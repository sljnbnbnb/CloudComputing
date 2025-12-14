import os
import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

DATA_DIR = 'results/mysql'
OUTPUT_DIR = 'analysis_charts'


def load_data(data_dir):
    records = []
    if not os.path.exists(data_dir):
        print(f"Error: Directory {data_dir} not found.")
        return pd.DataFrame()
    print(f"Reading files from {data_dir}...")
    for filename in os.listdir(data_dir):
        if filename.endswith('.json'):
            filepath = os.path.join(data_dir, filename)
            try:
                with open(filepath, 'r') as f:
                    data = json.load(f)
                    record = {
                        'Instance': data.get('instance_type', 'unknown'),
                        'Threads': int(data.get('threads', 0)),
                        'TPS': float(data.get('tps', 0)),
                        'QPS': float(data.get('qps', 0)),
                        'Latency Avg (ms)': float(data.get('latency_avg_ms', 0)),
                        'Latency 95th (ms)': float(data.get('latency_95th_ms', 0))
                    }
                    records.append(record)
            except Exception as e:
                print(f"Skipping {filename}: {e}")
    return pd.DataFrame(records)


def plot_charts(df):
    if df.empty:
        print("No data to plot.")
        return
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
    sns.set_theme(style="whitegrid")
    print("Generating MySQL TPS Chart...")
    plt.figure(figsize=(10, 6))
    sns.barplot(data=df, x="Threads", y="TPS", hue="Instance", palette="viridis")
    plt.title("MySQL Performance: Transactions Per Second (TPS)")
    plt.ylabel("TPS (Higher is Better)")
    plt.xlabel("Number of Threads")
    plt.savefig(f"{OUTPUT_DIR}/mysql_tps_comparison.png")
    plt.close()
    print("Generating MySQL QPS Chart...")
    plt.figure(figsize=(10, 6))
    sns.barplot(data=df, x="Threads", y="QPS", hue="Instance", palette="magma")
    plt.title("MySQL Performance: Queries Per Second (QPS)")
    plt.ylabel("QPS (Higher is Better)")
    plt.xlabel("Number of Threads")
    plt.savefig(f"{OUTPUT_DIR}/mysql_qps_comparison.png")
    plt.close()
    print("Generating MySQL Latency Chart...")
    plt.figure(figsize=(10, 6))
    sns.lineplot(data=df, x="Threads", y="Latency Avg (ms)", hue="Instance", style="Instance", markers=True, dashes=False, palette="deep")
    plt.title("MySQL Latency: Average Response Time")
    plt.ylabel("Latency (ms) - Lower is Better")
    plt.xlabel("Number of Threads")
    plt.savefig(f"{OUTPUT_DIR}/mysql_latency_comparison.png")
    plt.close()
    print(f"✓ All MySQL charts saved to local folder: {OUTPUT_DIR}/")


    
if __name__ == "__main__":
    df = load_data(DATA_DIR)
    print(f"Loaded {len(df)} records.")
    df = df.sort_values(by=['Threads'])
    print(df.head())
    plot_charts(df)