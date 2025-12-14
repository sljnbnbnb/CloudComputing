# Cloud Performance Benchmark Suite

This project is a comprehensive suite for benchmarking cloud instance performance, including CPU, Memory, Disk I/O, and application-level performance (MySQL, Nginx). It also includes analysis tools and an ML-based recommender system.

## Project Structure

```
cloud-performance-benchmark/
├── scripts/                  # Setup and benchmark scripts
│   ├── setup_tools.sh       # System-level dependency setup
│   ├── app_benchmarks/      # Application-specific scripts
│   │   ├── mysql_setup.sh
│   │   ├── mysql_benchmark.sh
│   │   ├── nginx_setup_only.sh
│   │   └── nginx_benchmark.sh
├── data/                    # Data storage
├── logs/                    # Execution logs
├── results/                 # Raw benchmark result files (JSON)
├── run_all_tests.sh         # Main orchestration script for basic benchmarks
├── analyze_results.py       # Analysis for basic benchmarks
├── analyze_mysql.py         # Analysis for MySQL benchmarks
├── analyze_nginx.py         # Analysis for Nginx benchmarks
└── ml_recommender.py        # ML-based instance recommender
```

## Workflow

Follow these steps to configure the environment, run benchmarks, and analyze the results.

### 1. Environment Configuration

Before running any tests, you must configure the environment and install necessary dependencies.

**System Dependencies:**
```bash
bash scripts/setup_tools.sh
```

**Application Setup:**
Configure MySQL and Nginx environments.
```bash
# Setup MySQL
bash scripts/app_benchmarks/mysql_setup.sh

# Setup Nginx
bash scripts/app_benchmarks/nginx_setup_only.sh
```

### 2. General Performance Benchmarking

Run the core system benchmarks (CPU, Memory, Disk I/O).

```bash
# Run all basic tests
./run_all_tests.sh
```

**Visualization:**
After running the tests, generate visualization results for the system metrics.
```bash
python3 analyze_results.py
```

### 3. Application Benchmarking

Switch to the app benchmarks directory to run specific application load tests.

```bash
cd scripts/app_benchmarks/

# Run MySQL Benchmark
bash mysql_benchmark.sh

# Run Nginx Benchmark
bash nginx_benchmark.sh
```

### 4. Application Analysis

Return to the root directory to analyze the application benchmark results.

```bash
cd ../../

# Analyze MySQL Results
python3 analyze_mysql.py

# Analyze Nginx Results
python3 analyze_nginx.py
```

### 5. ML-Based Recommendation

Finally, use the Machine Learning recommender to predict/recommend instance types based on the collected performance data.

```bash
python3 ml_recommender.py
```

## Output

- **Results**: Raw JSON data is stored in the `results/` directory.
- **Charts**: Generated charts and graphs are saved in `analysis_charts/` (or as configured in analysis scripts).
- **Logs**: Execution logs are available in `logs/`.
