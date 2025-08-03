# 🚀 Advanced MT4 Expert Advisor Framework

[![License](https://img.shields.io/badge/License-LGPL_3.0-blue)](https://licenses.nuget.org/LGPL-3.0-or-later)
[![MQL4](https://img.shields.io/badge/mql4-100%-purple.svg)](https://docs.mql4.com/)
[![MetaTrader](https://img.shields.io/badge/MetaTrader-4-blue.svg)](https://www.metatrader4.com/)


> **A sophisticated, modular trading system for MetaTrader 4 that combines advanced order management strategies with intelligent market analysis.**

## ✨ Features

### 🎯 **Intelligent Order Management**
- **Linear & Exponential Trailing Stops** - Protect profits with advanced stop-loss strategies
- **Pyramiding System** - Scale into winning positions intelligently
- **Grid Trading** - Automated grid-based position management
- **Risk Management** - Maximum loss, pip loss, and age-based order controls

### 💰 **Smart Money Management**
- **Fixed Lot Sizing** - Simple, consistent position sizes
- **Percentage-Based Sizing** - Risk based on account balance, equity, or margin
- **Square Root Scaling** - Advanced mathematical position sizing
- **Risk-Weighted Allocation** - Dynamic lot sizing based on market conditions

### 📊 **Technical Analysis Integration**
- **Moving Average + Parabolic SAR** - Dual-indicator trend confirmation
- **Customizable Indicators** - Easy-to-extend indicator framework
- **Multi-Timeframe Support** - Analyze trends across different time horizons

### 🏗️ **Modular Architecture**
- **Plugin-Based Design** - Mix and match strategies effortlessly
- **Interface-Driven** - Clean, extensible code architecture
- **Memory Management** - Automatic cleanup and resource optimization
- **Symbol & Magic Number Filtering** - Multi-pair, multi-strategy support

## 🚀 Quick Start

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
   ```bash
   # Using MetaEditor command line
   metaeditor.exe /portable /compile:TrailingStop.mq4
   ```
   Or open `TrailingStop.mq4` in MetaEditor and press F7

4. **Load in MetaTrader**
   - Restart MT4 or refresh Expert Advisors
   - Drag `TrailingStop` onto your chart
   - Configure parameters and enable automated trading

## ⚙️ Configuration

### Key Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `InitialTriggerPips` | Pips profit to activate trailing stop | 15.0 | 5-100 |
| `InitialPips` | Initial stop loss distance | 5.0 | 1-50 |
| `TrailingPips` | Trailing stop distance | 10.0 | 5-100 |
| `PyramidPips` | Distance between pyramid levels | 20.0 | 10-200 |
| `PyramidLotFactor` | Lot size multiplier for pyramiding | 1.0 | 0.1-5.0 |

### Strategy Combinations

The framework allows you to combine multiple strategies:

```mql4
// Example: Combine trailing stop with pyramiding
_managers.Add(new OrderManagers__LinearTrailingStop(15, 5, 10, Symbol()));
_managers.Add(new OrderManagers__Pyramid(20, 1.0, indicator, Symbol()));
```

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

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines.

## 📊 Architecture Overview

```
MQ4ExpertAdvisors/
├── Experts/
│   └── TrailingStop.mq4          # Main Expert Advisor
├── Libraries/
│   ├── Core/
│   │   ├── IOrderManager.mqh     # Order management interface
│   │   ├── IMoneyManager.mqh     # Money management interface
│   │   └── IMarketIndicator.mqh  # Technical analysis interface
│   ├── OrderManagers/            # Trading strategies
│   ├── MoneyManagers/            # Position sizing strategies
│   └── MarketIndicators/         # Technical indicators
└── Documentation/
    ├── README.md                 # This file
    └── CLAUDE.md                 # Development guide
```

## 💝 Support This Project

### 🎯 If This EA Makes You Money

**Found success with this Expert Advisor?** Consider sharing the wealth! 

- **Profit Sharing**: If you're making consistent profits, consider donating 5-10% of your monthly gains
- **One-Time Donation**: Any amount helps fund continued development

### 💳 Donation Methods

- **GitHub**: Just click the "Sponsor" button at the top of this page

### 🤝 Other Ways to Support

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

## 📄 License

This project is licensed under the LGPLv3 License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

---

<div align="center">

**Made with ❤️ for the trading community**

*Remember: The best strategy is the one you understand and can stick to consistently!*

</div>