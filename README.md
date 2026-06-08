# 🚀 Advanced MT4 Expert Advisor Framework

[![License](https://img.shields.io/github/license/Hawkynt/MQ4ExpertAdvisors)](https://github.com/Hawkynt/MQ4ExpertAdvisors/blob/main/LICENSE)
[![Language](https://img.shields.io/github/languages/top/Hawkynt/MQ4ExpertAdvisors?color=8957D5)](https://github.com/Hawkynt/MQ4ExpertAdvisors)
[![MetaTrader 4](https://img.shields.io/badge/MetaTrader_4-informational)](https://www.metatrader4.com/)

[![CI](https://github.com/Hawkynt/MQ4ExpertAdvisors/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Hawkynt/MQ4ExpertAdvisors/actions/workflows/ci.yml)
![Last Commit](https://img.shields.io/github/last-commit/Hawkynt/MQ4ExpertAdvisors?branch=main)
![Activity](https://img.shields.io/github/commit-activity/m/Hawkynt/MQ4ExpertAdvisors)

[![Stars](https://img.shields.io/github/stars/Hawkynt/MQ4ExpertAdvisors?color=FFD700)](https://github.com/Hawkynt/MQ4ExpertAdvisors/stargazers)
[![Forks](https://img.shields.io/github/forks/Hawkynt/MQ4ExpertAdvisors?color=008080)](https://github.com/Hawkynt/MQ4ExpertAdvisors/network/members)
[![Issues](https://img.shields.io/github/issues/Hawkynt/MQ4ExpertAdvisors)](https://github.com/Hawkynt/MQ4ExpertAdvisors/issues)
![Code Size](https://img.shields.io/github/languages/code-size/Hawkynt/MQ4ExpertAdvisors?color=4CAF50)
![Repo Size](https://img.shields.io/github/repo-size/Hawkynt/MQ4ExpertAdvisors?color=FF9800)

[![Release](https://img.shields.io/github/v/release/Hawkynt/MQ4ExpertAdvisors)](https://github.com/Hawkynt/MQ4ExpertAdvisors/releases/latest)
[![Nightly](https://img.shields.io/github/v/release/Hawkynt/MQ4ExpertAdvisors?include_prereleases&sort=date&filter=nightly-*&label=nightly&color=FF9800)](https://github.com/Hawkynt/MQ4ExpertAdvisors/releases)
[![Downloads](https://img.shields.io/github/downloads/Hawkynt/MQ4ExpertAdvisors/total)](https://github.com/Hawkynt/MQ4ExpertAdvisors/releases)

> A modular trading system for MetaTrader 4 that combines advanced order-management strategies (trailing stops, grid recovery, partial closes) with indicator-driven market analysis — built so each expert advisor, indicator and library can be used and tested on its own.

## ✨ Features

### 🎯 **Intelligent Order Management**

- **Linear & Exponential Trailing Stops** - Protect profits with advanced stop-loss strategies
- **ATR-Based Trailing Stop** - Volatility-adaptive stop loss distance
- **Break-Even Stop** - Move stop to entry after reaching profit target
- **Partial Take Profit** - Close portion of position at target, trail remainder
- **Pyramiding System** - Scale into winning positions intelligently
- **Grid Trading** - Automated grid-based position management
- **Time-Based Close** - Close positions at specific times (e.g., Friday close)
- **Risk Management** - Maximum loss, pip loss, and age-based order controls

### 💰 **Smart Money Management**

- **Fixed Lot Sizing** - Simple, consistent position sizes
- **Percentage-Based Sizing** - Risk based on account balance, equity, or margin
- **Square Root Scaling** - Advanced mathematical position sizing
- **Risk-Weighted Allocation** - Dynamic lot sizing based on stop loss
- **Kelly Criterion** - Optimal position sizing based on win rate and risk/reward
- **ATR-Based Sizing** - Scale positions inversely with market volatility
- **Drawdown Limiter** - Automatically reduce size during account drawdowns
- **Max Exposure Cap** - Limit total exposure across all positions

### 📊 **Technical Analysis Integration**

- **Moving Average Crossover** - Classic trend-following signals
- **Parabolic SAR** - Trend reversal detection
- **MA + Parabolic SAR Combo** - Dual-indicator trend confirmation
- **RSI (Relative Strength Index)** - Overbought/oversold momentum signals
- **MACD** - Moving Average Convergence Divergence for momentum and trend
- **Bollinger Bands** - Volatility-based mean reversion signals
- **ADX (Average Directional Index)** - Trend strength confirmation
- **Stochastic Oscillator** - Momentum reversal signals with K/D crossovers
- **Fully Configurable** - All indicators support custom timeframes and parameters

### 🏗️ **Modular Architecture**

- **Plugin-Based Design** - Mix and match strategies effortlessly
- **Interface-Driven** - Clean, extensible code architecture
- **Memory Management** - Automatic cleanup and resource optimization
- **Symbol & Magic Number Filtering** - Multi-pair, multi-strategy support

## 📦 Quick Start

### Prerequisites

- MetaTrader 4 platform
- MetaEditor (included with MT4)
- Basic understanding of forex trading concepts

### Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Hawkynt/MQ4ExpertAdvisors.git
   ```

2. **Copy Files to MT4**
   - Copy `Experts/` folder to your MT4 `MQL4/Experts/` directory
   - Copy `Libraries/` folder to your MT4 `MQL4/Include/` directory

3. **Compile the Expert Advisor**

   ```powershell
   # Using the build script (recommended)
   .\Scripts\Build.ps1

   # Or compile a specific EA
   .\Scripts\Build.ps1 -File "AdaptiveTrader.mq4"
   ```

   Or open the `.mq4` file in MetaEditor and press F7

4. **Load in MetaTrader**
   - Restart MT4 or refresh Expert Advisors
   - Drag `TrailingStop` onto your chart
   - Configure parameters and enable automated trading

## ⚙️ Configuration

### Key Parameters

| Parameter            | Description                           | Default | Range   |
| -------------------- | ------------------------------------- | ------- | ------- |
| `InitialTriggerPips` | Pips profit to activate trailing stop | 15.0    | 5-100   |
| `InitialPips`        | Initial stop loss distance            | 5.0     | 1-50    |
| `TrailingPips`       | Trailing stop distance                | 10.0    | 5-100   |
| `PyramidPips`        | Distance between pyramid levels       | 20.0    | 10-200  |
| `PyramidLotFactor`   | Lot size multiplier for pyramiding    | 1.0     | 0.1-5.0 |

### Strategy Combinations

The framework allows you to combine multiple strategies:

```mql4
// Example: Combine trailing stop with pyramiding
_managers.Add(new OrderManagers__LinearTrailingStop(15, 5, 10, Symbol()));
_managers.Add(new OrderManagers__Pyramid(20, 1.0, indicator, Symbol()));
```

## 🔧 Build & Test Tools

The `Scripts/` folder contains PowerShell tools for automated building, testing, and report analysis.

### BuildAndTest.ps1

Full workflow automation: compile, deploy, test, and analyze in one command.

```powershell
# Test the default EA (AdaptiveTrader) with default settings
.\Scripts\BuildAndTest.ps1

# Test a specific EA
.\Scripts\BuildAndTest.ps1 -Expert "MyStrategy"

# Override symbol and period
.\Scripts\BuildAndTest.ps1 -Expert "MyStrategy" -Symbol "EURUSD" -Period "M15"

# Build all EAs
.\Scripts\BuildAndTest.ps1 -All

# Just build and deploy without launching MT4
.\Scripts\BuildAndTest.ps1 -NoLaunch
```

**Workflow Steps:**

1. Compiles the Expert Advisor
2. Auto-detects MT4 terminal data folder
3. Deploys EA with configured test name
4. Updates `terminal.ini` with test parameters
5. Launches MT4 for backtesting
6. Waits for MT4 to close
7. Analyzes the saved report and generates enhanced HTML

### Build.ps1

Standalone compiler script for MQL4 files.

```powershell
# Build all .mq4 files in Experts folder
.\Scripts\Build.ps1

# Build a specific file
.\Scripts\Build.ps1 -File "AdaptiveTrader.mq4"
```

### AnalyzeReport.ps1

Converts MT4 Strategy Tester HTML reports into enhanced interactive reports.

```powershell
.\Scripts\AnalyzeReport.ps1 -ReportPath "TestReports\StrategyTester.htm"

# Specify output directory
.\Scripts\AnalyzeReport.ps1 -ReportPath "report.htm" -OutputDir "C:\Reports"
```

**Enhanced Report Features:**

- Performance metrics (Net Profit, Profit Factor, Win Rate, Max Drawdown)
- Advanced metrics (Sharpe Ratio, Sortino Ratio, Recovery Factor, Z-Score)
- Interactive SVG charts (Equity curve, Drawdown, Profit distribution)
- Trade distribution by hour/weekday/month with market session coloring
- MFE/MAE analysis scatter plots
- Color-coded order book and event tables:
  - Time colored by market session (Asia=yellow, Europe=green, USA=red)
  - Volume colored by size (brown to golden gradient)
  - S/L colored by profit zone (lightgreen=profit, salmon=loss)
  - T/P colored blue when set
  - Close type colored by result (lime=profit, red=loss)

### BuildAndTest.ini

Configuration file for the build and test workflow.

```ini
[MT4]
; Path to MetaTrader executable or launcher batch file
Terminal=X:\Path\To\MT4\terminal.exe
Compiler=X:\Path\To\MT4\metaeditor.exe

; AppData root where MT4 stores its data (terminal ID auto-detected)
AppDataRoot=X:\Path\To\MT4\AppData\MetaQuotes\Terminal

[Test]
; Name for the deployed test expert
ExpertName=_TEST_

; Default backtest parameters
Symbol=EURJPY
Period=H1
Model=1
FromDate=2000.01.01
ToDate=2025.12.31
```

| Parameter     | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| `Terminal`    | Path to MT4 executable or launcher script                      |
| `Compiler`    | Path to MetaEditor.exe for compilation                         |
| `AppDataRoot` | MT4 AppData folder (terminal ID auto-detected)                 |
| `ExpertName`  | Name used when deploying EA for testing                        |
| `Symbol`      | Default trading symbol for backtests                           |
| `Period`      | Default timeframe (M1, M5, M15, M30, H1, H4, D1, W1, MN)       |
| `Model`       | Backtest model (0=Every tick, 1=Control points, 2=Open prices) |
| `FromDate`    | Backtest start date                                            |
| `ToDate`      | Backtest end date                                              |

## 📈 Performance & Results

### Backtesting Recommendations

- Test on multiple currency pairs (EUR/USD, GBP/USD, USD/JPY)
- Use tick data for accurate results
- Test across different market conditions (trending, ranging, volatile)
- Validate with at least 1 year of historical data

### Risk Management

- **Maximum Risk**: Never risk more than 2% per trade
- **Diversification**: Use across multiple uncorrelated pairs
- **Regular Monitoring**: Review performance weekly
- **Stop Loss**: Always use appropriate stop losses

## 🛠️ Development

### Adding New Strategies

**Order Manager Example:**

```mql4
class MyCustomManager : public IOrderManager {
    virtual void Manage() {
        // Your custom logic here
    }
};
```

**Money Manager Example:**

```mql4
class MyMoneyManager : public IMoneyManager {
    virtual double CalculateLots(Order* order) {
        // Your position sizing logic
        return calculatedLots;
    }
};
```

## 📊 Architecture Overview

```
MQ4ExpertAdvisors/
├── Experts/
│   ├── AdaptiveTrader.mq4        # Main Expert Advisor
│   └── *.mq4                     # Other Expert Advisors
├── Libraries/
│   ├── Core/
│   │   ├── IOrderManager.mqh     # Order management interface
│   │   ├── IMoneyManager.mqh     # Money management interface
│   │   └── IMarketIndicator.mqh  # Technical analysis interface
│   ├── OrderManagers/            # Trading strategies
│   ├── MoneyManagers/            # Position sizing strategies
│   └── MarketIndicators/         # Technical indicators
├── Scripts/
│   ├── Build.ps1                 # MQL4 compiler script
│   ├── BuildAndTest.ps1          # Full build/test/analyze workflow
│   ├── BuildAndTest.ini          # Configuration for build/test
│   ├── AnalyzeReport.ps1         # Report analyzer
│   └── ReportTemplate.html       # Enhanced report template
├── TestReports/                  # Generated backtest reports
└── README.md                     # This file
```

## 🤝 Contributing

- ⭐ **Star this repository** if you find it useful
- 🐛 **Report bugs** and suggest improvements
- 📖 **Contribute documentation** or code improvements
- 📢 **Share with other traders** who might benefit

### 💼 Commercial License

Using this EA in a commercial trading environment? Consider purchasing a commercial license for:

- Priority support
- Custom strategy development
- Performance optimization consultations
- White-label licensing options

**Contact**: Via GitHub

---

## ⚠️ Disclaimer

**TRADING INVOLVES SUBSTANTIAL RISK OF LOSS**

- Past performance is not indicative of future results
- Only trade with money you can afford to lose
- This software is provided "as-is" without warranty
- The author is not responsible for any trading losses
- Always test thoroughly in demo accounts first
- Consider seeking advice from qualified financial advisors

## ❤️ Support

If this project saves you time or money, consider supporting its development — if this EA earns for you, sharing a slice of a profitable month funds the next feature:

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsor-EA4AAA?logo=githubsponsors)](https://github.com/sponsors/Hawkynt)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-00457C?logo=paypal)](https://www.paypal.me/hawkynt)

## 📜 License

Licensed under LGPL-3.0-or-later — see [LICENSE](LICENSE).
