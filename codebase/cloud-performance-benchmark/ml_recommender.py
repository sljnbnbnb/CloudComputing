import pandas as pd
import numpy as np
from sklearn.tree import DecisionTreeClassifier, export_text
from sklearn.preprocessing import LabelEncoder
import os
def create_knowledge_base():
    data = [
        [9, 2, 'Compute', 'No', 'c5.large'],
        [8, 4, 'Web',     'No', 'c5.large'],
        [10,2, 'Compute', 'Yes','c5.large'],
        [5, 8, 'DB',      'No', 'm5.large'],
        [4, 7, 'DB',      'Yes','m5.large'],
        [6, 8, 'Web',     'No', 'm5.large'],
        [2, 2, 'Dev',     'Yes','t3.medium'],
        [3, 4, 'Dev',     'No', 't3.medium'],
        [4, 2, 'Web',     'Yes','t3.medium'],
        [1, 1, 'Dev',     'Yes','t3.medium'],
    ]
    columns = ['cpu_intensity', 'memory_gb', 'workload_type', 'budget_sensitive', 'recommended_instance']
    return pd.DataFrame(data, columns=columns)
def train_model():
    df = create_knowledge_base()
    encoders = {}
    for col in ['workload_type', 'budget_sensitive']:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col])
        encoders[col] = le
    X = df.drop('recommended_instance', axis=1)
    y = df['recommended_instance']
    clf = DecisionTreeClassifier(max_depth=5, random_state=42)
    clf.fit(X, y)
    return clf, encoders
def make_recommendation(model, encoders, cpu, mem, workload, budget):
    try:
        w_val = encoders['workload_type'].transform([workload])[0]
        b_val = encoders['budget_sensitive'].transform([budget])[0]
    except ValueError:
        return "Unknown Input", {}, []
    input_data = [[cpu, mem, w_val, b_val]]
    prediction = model.predict(input_data)[0]
    probs = model.predict_proba(input_data)[0]
    return prediction, probs, model.classes_
if __name__ == "__main__":
    print("="*60)
    print("Cloud Instance Recommender System (Final Project Component)")
    print("Based on benchmarks: Sysbench, FIO, iperf3, MySQL, Nginx")
    print("="*60)
    model, encoders = train_model()
    print("✓ Model trained successfully on benchmark knowledge base.\n")
    test_cases = [
        {'name': 'High-Traffic Web Server', 'params': [8, 4, 'Web', 'No']},
        {'name': 'Production MySQL DB',     'params': [5, 8, 'DB',  'No']},
        {'name': 'Student Dev Environment', 'params': [2, 2, 'Dev', 'Yes']}
    ]
    output_path = "analysis_charts/ml_recommendation_report.txt"
    with open(output_path, "w") as f:
        f.write("Instance Recommendation Report\n")
        f.write("==============================\n\n")
        for case in test_cases:
            p = case['params']
            rec, probs, classes = make_recommendation(model, encoders, *p)
            print(f"Scenario: {case['name']}")
            print(f"  Input: CPU={p[0]}, Mem={p[1]}GB, Type={p[2]}, Budget={p[3]}")
            print(f"  >>> Recommendation: {rec}")
            print("-" * 40)
            f.write(f"Scenario: {case['name']}\n")
            f.write(f"  Input: {p}\n")
            f.write(f"  Recommendation: {rec}\n")
            f.write(f"  Confidence: {dict(zip(classes, probs))}\n\n")
        tree_rules = export_text(model, feature_names=['CPU', 'Mem', 'Type', 'Budget'])
        print("\n[Internal Decision Logic]")
        print(tree_rules)
        f.write("Decision Tree Logic:\n")
        f.write(tree_rules)
    print(f"\n✓ Report generated at: {output_path}")
