import os
import pandas as pd
import pickle
import gzip
from imblearn.over_sampling import SMOTE
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import LabelEncoder, MinMaxScaler, StandardScaler
from sklearn.model_selection import train_test_split

class DataPreprocessor:
    def __init__(self, df_name):
        self.df_name = df_name
        self.original_feature_names = None  # Store original feature names

    def cleaning_data(self, df):
        df.drop(columns=["Naive_Bayes_Classifier_Attrition_Flag_Card_Category_Contacts_Count_12_mon_Dependent_count_Education_Level_Months_Inactive_12_mon_1",
                        "Naive_Bayes_Classifier_Attrition_Flag_Card_Category_Contacts_Count_12_mon_Dependent_count_Education_Level_Months_Inactive_12_mon_2",
                        "CLIENTNUM"], 
                        inplace=True)
        
        Q1 = df['Months_on_book'].quantile(0.25)
        Q3 = df['Months_on_book'].quantile(0.75)
        IQR = Q3 - Q1
        lower_bound = Q1 - 1.5 * IQR
        upper_bound = Q3 + 1.5 * IQR
        df = df[(df['Months_on_book'] >= lower_bound) & (df['Months_on_book'] <= upper_bound)]

        df = df.applymap(lambda x: None if x == 'Unknown' else x)
        return df

    def imputer(self, X_train, X_test):
        imputer_cat = SimpleImputer(strategy='most_frequent')
        imputer_num = SimpleImputer(strategy='median')

        categorical_features = X_train.select_dtypes(include=['object']).columns
        numerical_features = X_train.select_dtypes(include=['int64', 'float64']).columns

        X_train[categorical_features] = imputer_cat.fit_transform(X_train[categorical_features])
        X_test[categorical_features] = imputer_cat.transform(X_test[categorical_features])

        X_train[numerical_features] = imputer_num.fit_transform(X_train[numerical_features])
        X_test[numerical_features] = imputer_num.transform(X_test[numerical_features])

        return X_train, X_test

    def encoder(self, X_train, X_test):
        encoder = LabelEncoder()
        categorical_cols = X_train.select_dtypes('object').columns
        for col in categorical_cols:
            X_train[col] = encoder.fit_transform(X_train[col])
            X_test[col] = X_test[col].map(lambda s: encoder.transform([s])[0] if s in encoder.classes_ else -1)
        return X_train, X_test

    def normalize(self, X_train, X_test):
        norm_scaler = MinMaxScaler()
        X_train_normalized = norm_scaler.fit_transform(X_train)
        X_test_normalized = norm_scaler.transform(X_test)
        return X_train_normalized, X_test_normalized
    
    def standardize(self, X_train, X_test):
        stand_scaler = StandardScaler()
        X_train_standardized = stand_scaler.fit_transform(X_train)
        X_test_standardized = stand_scaler.transform(X_test)
        return X_train_standardized, X_test_standardized
  
    def preprocess(self):
        self.df_name = self.cleaning_data(self.df_name)
        X = self.df_name.drop('Attrition_Flag', axis=1)
        y = self.df_name['Attrition_Flag']
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        X_train, X_test = self.imputer(X_train, X_test)
        X_train, X_test = self.encoder(X_train, X_test)
        X_train, X_test = self.normalize(X_train, X_test)
        X_train, X_test = self.standardize(X_train, X_test)
        smote = SMOTE(random_state=42)
        X_train, y_train = smote.fit_resample(X_train, y_train)
        
        label_encoder = LabelEncoder()
        y_train = label_encoder.fit_transform(y_train)
        y_test = label_encoder.transform(y_test)

        self.original_feature_names = X.columns.tolist()

        return X_train, X_test, y_train, y_test

