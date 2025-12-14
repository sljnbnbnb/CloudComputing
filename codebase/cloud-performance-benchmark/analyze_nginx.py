import os
import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

PRICES = {
    't3.medium': 0.0416,
    'm5.large': 0.0960,
    'c5.large': 0.0850
}

DATA_DIR = 'results/nginx'
OUTPUT_DIR = 'analysis_charts'


def parse_transfer_rate(value_str):
    """
    Parse wrk transfer rate, convert to MB/s
    Supports: 2.01gb, 300mb, 400kb
    """
    val = str(value_str).lower()
    try:
        if 'gb' in val:
            return float(val.replace('gb', '')) * 1024
        elif 'mb' in val:
            return float(val.replace('mb', ''))
        elif 'kb' in val:
            return float(val.replace('kb', '')) / 1024
        elif 'b' in val:
            return float(val.replace('b', '')) / (1024 * 1024)
        else:
            return float(val)
    except ValueError:
        return 0.0

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
                    lat_str = str(data.get('latency_avg', '0')).lower()
                    if 'ms' in lat_str:
                        lat_val = float(lat_str.replace('ms', ''))
                    elif 's' in lat_str and 'us' not in lat_str:
                        lat_val = float(lat_str.replace('s', '')) * 1000
                    elif 'us' in lat_str:
                        lat_val = float(lat_str.replace('us', '')) / 1000
                    else:
                        lat_val = float(lat_str)
                    transfer_str = data.get('transfer_per_sec', '0MB')
                    transfer_val = parse_transfer_rate(transfer_str)
                    rps = float(data.get('requests_per_sec', 0))
                    record = {
                        'Instance': data.get('instance_type', 'unknown'),
                        'File Size': data.get('target_file', '').replace('static/', ''),
                        'Concurrency': int(data.get('connections', 0)),
                        'RPS': rps,
                        'Latency (ms)': lat_val,
                        'Transfer (MB/s)': transfer_val
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
    print("Generating RPS Chart...")
    g = sns.catplot(
        data=df, x="Concurrency", y="RPS", hue="Instance", col="File Size",
        kind="bar", height=5, aspect=0.8, palette="viridis",
        col_order=["1kb.html", "10kb.html", "100kb.html"]
    )
    g.fig.subplots_adjust(top=0.85)
    g.fig.suptitle('Nginx Throughput (Requests/Sec) Comparison')
    g.savefig(f"{OUTPUT_DIR}/nginx_rps_comparison.png")
    print("Generating Latency Chart...")
    g = sns.catplot(
        data=df, x="Concurrency", y="Latency (ms)", hue="Instance", col="File Size",
        kind="point", height=5, aspect=0.8, palette="magma",
        col_order=["1kb.html", "10kb.html", "100kb.html"]
    )
    g.fig.subplots_adjust(top=0.85)
    g.fig.suptitle('Nginx Average Latency Comparison')
    g.savefig(f"{OUTPUT_DIR}/nginx_latency_comparison.png")
    print("Generating Cost Efficiency Chart...")
    df['Price ($/hr)'] = df['Instance'].map(PRICES)
    df['Requests Per Dollar'] = (df['RPS'] * 3600) / df['Price ($/hr)']
    plt.figure(figsize=(10, 6))
    subset = df[(df['File Size'] == '1kb.html') & (df['Concurrency'] == 1000)]
    if not subset.empty:
        chart = sns.barplot(data=subset, x="Instance", y="Requests Per Dollar", hue="Instance", palette="Blues_d")
        plt.title("Cost Efficiency: Requests Served per Dollar (1KB File, 1000 Conn)")
        plt.ylabel("Requests / $1")
        plt.tight_layout()
        plt.savefig(f"{OUTPUT_DIR}/nginx_cost_efficiency.png")
    else:
        print("Skipping Cost Efficiency Chart: No data for 1kb.html at 1000 concurrency")
    print(f"✓ All charts saved to local folder: {OUTPUT_DIR}/")



    
if __name__ == "__main__":
    df = load_data(DATA_DIR)
    print(f"Loaded {len(df)} records.")
    plot_charts(df)