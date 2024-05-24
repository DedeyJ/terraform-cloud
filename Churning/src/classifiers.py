import mlflow
import optuna
import os
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

from preprocessing import DataPreprocessor

# to allow logging
optuna.logging.set_verbosity(optuna.logging.ERROR)


####################################################
### Setup to allow tracking with MLFlow in Cloud ###
####################################################

# The Mlflow is set up to require login credentials.  
os.environ["MLFLOW_TRACKING_USERNAME"] = 'mlflow-user' # Is setup to be that username standard, if you change it, change it here as well.
os.environ["MLFLOW_TRACKING_PASSWORD"] =  'mlflow_password' # Looks this up in the AWS parameter store


mlflow.set_tracking_uri('mlflow_tracking_uri') # Look this up in AWS parameter store or in the ECS information in AWS.


#############################
### Creation of Functions ###
#############################

def get_or_create_experiment(experiment_name):
    """
    Retrieve the ID of an existing MLflow experiment or create a new one if it doesn't exist.

    This function checks if an experiment with the given name exists within MLflow.
    If it does, the function returns its ID. If not, it creates a new experiment
    with the provided name and returns its ID.

    Parameters:
    - experiment_name (str): Name of the MLflow experiment.

    Returns:
    - str: ID of the existing or newly created MLflow experiment.
    """

    if experiment := mlflow.get_experiment_by_name(experiment_name):
        return experiment.experiment_id
    else:
        return mlflow.create_experiment(experiment_name)
    
def champion_callback(study, frozen_trial):
    """
    Logging callback that will report when a new trial iteration improves upon existing
    best trial values.

    Note: This callback is not intended for use in distributed computing systems such as Spark
    or Ray due to the micro-batch iterative implementation for distributing trials to a cluster's
    workers or agents.
    The race conditions with file system state management for distributed trials will render
    inconsistent values with this callback.
    """

    winner = study.user_attrs.get("winner", None)

    if study.best_value and winner != study.best_value:
        study.set_user_attr("winner", study.best_value)
        if winner:
            improvement_percent = (abs(winner - study.best_value) / study.best_value) * 100
            print(
                f"Trial {frozen_trial.number} achieved value: {frozen_trial.value} with "
                f"{improvement_percent: .4f}% improvement"
            )
        else:
            print(f"Initial trial {frozen_trial.number} achieved value: {frozen_trial.value}")

def objective(trial):
    with mlflow.start_run(nested=True):
        # Define hyperparameters
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 10, 100),
            "max_depth": trial.suggest_int("max_depth", 1, 32),
            "min_samples_split": trial.suggest_float("min_samples_split", 0.1, 1.0),
            "min_samples_leaf": trial.suggest_float("min_samples_leaf", 0.1, 0.5),
            "max_features": trial.suggest_categorical("max_features", [None, "sqrt", "log2"]),
            "bootstrap": trial.suggest_categorical("bootstrap", [True, False])
        }
              
        # Train Random Forest Classifier
        rf = RandomForestClassifier(**params)
        rf.fit(X_train, y_train)
        preds = rf.predict(X_test)
        accuracy = accuracy_score(y_test, preds)

    return 1 - accuracy  # Optuna minimizes the objective function, so we return 1 - accuracy


################################################
### Preparations before tracking with MLFlow ###
################################################

run_name = "hyper-parameter-tuning"

experiment_id = get_or_create_experiment("Churning")

current_directory = os.path.dirname(__file__)
csv_file_path = os.path.join(current_directory, "..", "data", "BankChurners.csv")
churners_df = pd.read_csv(csv_file_path, sep=',')


# Instantiate the class with the dataframe name
preprocessor = DataPreprocessor(df_name=churners_df)

# Use the preprocess method to get preprocessed data
X_train, X_test, y_train, y_test = preprocessor.preprocess()


##############
### MLFlow ###
##############

# Initiate the parent run and call the hyperparameter tuning child run logic
mlflow.autolog()
with mlflow.start_run(experiment_id=experiment_id, run_name=run_name, nested=True) as run:
    # Initialize the Optuna study
    study = optuna.create_study(direction="minimize")

    # Execute the hyperparameter optimization trials.
    # Note the addition of the `champion_callback` inclusion to control our logging
    study.optimize(objective, n_trials=20, callbacks=[champion_callback])

    # Log tags
    mlflow.set_tags(
        tags={
            "project": "Churn Project",
            "optimizer_engine": "optuna",
            "model_family": "random_forest_classifier",
            "feature_set_version": 1,
        }
    )

    # Log a fit model instance
    best_rf = RandomForestClassifier(**study.best_params)
    best_rf.fit(X_train, y_train)

    artifact_path = "model"

    mlflow.sklearn.log_model(
        sk_model=best_rf,
        artifact_path=artifact_path,
        input_example=X_train,
        registered_model_name="RandomForestClassifier_Model",
    )

    # Get the logged model uri so that we can load it from the artifact store
    model_uri = mlflow.get_artifact_uri(artifact_path)
    print(model_uri)

    run_id = run.info.run_id
    print(f"Run ID: {run_id}")



