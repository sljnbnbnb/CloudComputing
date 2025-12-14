#!/usr/bin/env python3
"""
Cloud Performance Benchmark - Results Analysis Script
Analyzes benchmark results and generates visualizations
"""
import json
import os
import glob
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)

class BenchmarkAnalyzer:
    def __init__(self, results_dir='./results'):
        self.results_dir = results_dir
        self.data = {
            'cpu': [],
            'memory': [],
            'disk': [],
            'network': []
        }

    def load_results(self):
        """Load all JSON result files"""
        for test_type in self.data.keys():
            pattern = f"{self.results_dir}/{test_type}/*.json"
            for file_path in glob.glob(pattern):
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                        for line in content.strip().split('\n'):
                            if line.strip():
                                data = json.loads(line)
                                self.data[test_type].append(data)
                except Exception as e:
                    print(f"Error loading {file_path}: {e}")

    def analyze_cpu(self):
        """Analyze CPU benchmark results"""
        if not self.data['cpu']:
            print("No CPU data available")
            return
        df = pd.DataFrame(self.data['cpu'])
        summary = df.groupby('instance_type')['events_per_second'].agg([
            'mean', 'std', 'min', 'max'
        ]).round(2)
        print("\n" + "="*60)
        print("CPU Performance Summary (Events per Second)")
        print("="*60)
        print(summary)
        plt.figure(figsize=(10, 6))
        df_pivot = df.pivot_table(
            values='events_per_second',
            index='instance_type',
            columns='threads',
            aggfunc='mean'
        )
        df_pivot.plot(kind='bar', ax=plt.gca())
        plt.title('CPU Performance Comparison')
        plt.xlabel('Instance Type')
        plt.ylabel('Events per Second')
        plt.legend(title='Threads')
        plt.tight_layout()
        plt.savefig(f"{self.results_dir}/cpu_performance.png", dpi=300)
        print(f"\n✓ Chart saved: {self.results_dir}/cpu_performance.png")


    def analyze_memory(self):
        """Analyze memory benchmark results"""
        if not self.data['memory']:
            print("No memory data available")
            return
        df = pd.DataFrame(self.data['memory'])
        summary = df.groupby(['instance_type', 'operation'])['bandwidth_mibs'].mean().unstack()
        print("\n" + "="*60)
        print("Memory Bandwidth Summary (MiB/sec)")
        print("="*60)
        print(summary.round(2))
        plt.figure(figsize=(10, 6))
        summary.plot(kind='bar', ax=plt.gca())
        plt.title('Memory Bandwidth Comparison')
        plt.xlabel('Instance Type')
        plt.ylabel('Bandwidth (MiB/sec)')
        plt.legend(title='Operation')
        plt.tight_layout()
        plt.savefig(f"{self.results_dir}/memory_performance.png", dpi=300)
        print(f"✓ Chart saved: {self.results_dir}/memory_performance.png")


    def analyze_disk(self):
        """Analyze disk I/O benchmark results"""
        if not self.data['disk']:
            print("No disk data available")
            return
        df = pd.DataFrame(self.data['disk'])
        summary = df.groupby(['instance_type', 'io_type']).agg({
            'iops': 'mean',
            'bandwidth_kbs': 'mean'
        }).round(2)
        print("\n" + "="*60)
        print("Disk I/O Performance Summary")
        print("="*60)
        print(summary)
        fig, axes = plt.subplots(1, 2, figsize=(14, 6))
        iops_pivot = df.groupby(['instance_type', 'io_type'])['iops'].mean().unstack()
        iops_pivot.plot(kind='bar', ax=axes[0])
        axes[0].set_title('IOPS Comparison')
        axes[0].set_xlabel('Instance Type')
        axes[0].set_ylabel('IOPS')
        bw_pivot = df.groupby(['instance_type', 'io_type'])['bandwidth_kbs'].mean().unstack()
        bw_pivot.plot(kind='bar', ax=axes[1])
        axes[1].set_title('Bandwidth Comparison')
        axes[1].set_xlabel('Instance Type')
        axes[1].set_ylabel('Bandwidth (KB/s)')
        plt.tight_layout()
        plt.savefig(f"{self.results_dir}/disk_performance.png", dpi=300)
        print(f"✓ Chart saved: {self.results_dir}/disk_performance.png")


    def analyze_network(self):
        """Analyze network benchmark results"""
        if not self.data['network']:
            print("No network data available")
            return
        df = pd.DataFrame(self.data['network'])
        summary = df.groupby(['instance_type', 'parallel_streams'])['bandwidth_mbps'].mean().unstack()
        print("\n" + "="*60)
        print("Network Bandwidth Summary (Mbps)")
        print("="*60)
        print(summary.round(2))
        plt.figure(figsize=(10, 6))
        summary.plot(kind='bar', ax=plt.gca())
        plt.title('Network Bandwidth Comparison')
        plt.xlabel('Instance Type')
        plt.ylabel('Bandwidth (Mbps)')
        plt.legend(title='Parallel Streams')
        plt.tight_layout()
        plt.savefig(f"{self.results_dir}/network_performance.png", dpi=300)
        print(f"✓ Chart saved: {self.results_dir}/network_performance.png")


    def generate_report(self):
        """Generate comprehensive performance report"""
        print("\n" + "="*60)
        print("CLOUD PERFORMANCE BENCHMARK - COMPREHENSIVE REPORT")
        print("="*60)
        print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        self.analyze_cpu()
        self.analyze_memory()
        self.analyze_disk()
        self.analyze_network()
        print("\n" + "="*60)
        print("Report generation completed!")
        print("="*60)



def main():
    analyzer = BenchmarkAnalyzer()
    analyzer.load_results()
    analyzer.generate_report()


    
if __name__ == "__main__":
    main()