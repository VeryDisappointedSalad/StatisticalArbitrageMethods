# StatisticalArbitrageMethods
Repository for group A for Statistical Arbitrage Methods 2025Z @MIMUW. The subject was to build a trading strategy on semiconductor/ technology sector minute frequency stocks and test, whether ensembling financial data with sentiment analysis from news may improve overall return. The project was divided into several parts.

# Financial data scraping `FinancialDataScraping.ipynb`
This notebook is designed to fetch and compile historical stock data for major microprocessor and semiconductor companies from Polygon.io. It aims to facilitate backtesting and analysis of statistical arbitrage strategies by providing detailed minute-level stock price data for companies like NVIDIA, AMD, Intel, and others over a specified period.
# News data scraping

# Parsing data and feature engineering `FeatureEngineering.ipynb`
This notebook takes in the financial and news input and aggregates them into seperate .csv files, each one consisting of `price`, `VADER_score` and `sentiment` in minute frequency.

# Constructing the LSTM model and backtesting `LSTM.ipynb`
This notebook creates two models for each of the `ticker`s available (one BASE, having only financial inputs, and NLP - boosted with `sentiment` and `VADER` score), resulting in overall 20 models and 20 equity curves.

# Ensembling the financial basket and displaying the backtest data `PerformanceMetrics.ipynb`
This notebook generates metrics for strategies mentioned.

