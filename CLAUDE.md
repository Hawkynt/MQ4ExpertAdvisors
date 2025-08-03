# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment

This is a MetaTrader 4 (MT4) Expert Advisor codebase written in MQL4. Development requires:
- MetaTrader 4 platform with MetaEditor
- No external build tools or package managers are used
- Files are compiled directly in MetaEditor

## Architecture Overview

This codebase implements a modular trading system using object-oriented design patterns:

### Core Components

**Expert Advisors** (`Experts/`):
- `TrailingStop.mq4` - Main EA that combines multiple order management strategies
- Uses composition pattern to combine different managers and indicators

**Library Structure** (`Libraries/`):
- **Base Classes**: `Object.mqh` (base class), `Common.mqh` (utilities and exceptions)
- **Interfaces**: `IOrderManager.mqh`, `IMoneyManager.mqh`, `IMarketIndicator.mqh`
- **Data Structures**: `List.mqh`, `Order.mqh`, `OrderCollection.mqh`, `Instrument.mqh`

**Strategy Implementation Folders**:
- **OrderManagers/**: Trade management strategies (trailing stops, pyramiding, grid, etc.)
- **MoneyManagers/**: Position sizing strategies (fixed lots, percentage-based, risk-based)
- **MarketIndicators/**: Technical analysis indicators for entry/exit signals

### Design Patterns

1. **Interface Segregation**: Separate interfaces for order management, money management, and market indicators
2. **Strategy Pattern**: Pluggable managers for different trading strategies
3. **Composition over Inheritance**: EA composes multiple managers rather than inheriting behavior
4. **Collection Management**: `OrderCollection` provides filtering and aggregation methods

### Key Architectural Features

- **Manager System**: The EA uses a `List` of `IOrderManager` instances that execute on each tick
- **Symbol Filtering**: Managers can be configured to work with specific currency pairs
- **Magic Number Support**: Order filtering by magic numbers for multi-strategy operations
- **Memory Management**: Automatic disposal of objects through destructors and auto-dispose lists

## File Naming Conventions

- Classes use namespace-like naming: `OrderManagers__LinearTrailingStop`, `MoneyManagers__FixedLotSize`
- Interfaces prefixed with `I`: `IOrderManager`, `IMoneyManager`
- Abstract base classes prefixed with `A`: `AExistingOrdersManager`

## Development Workflow

Since this is MQL4 code:
1. Edit `.mq4` and `.mqh` files in MetaEditor or any text editor
2. Compile in MetaEditor to generate `.ex4` files: "X:\PortableApps\Ava_MetaTrader_4\metaeditor.exe /portable /compile:<filename.mq4>"
3. Verify that <filename.ex4> is generated in the `Experts/` directory
4. Manually test in MetaTrader 4 Strategy Tester

## Adding New Components

**New Order Manager**:
1. Inherit from `IOrderManager` or `AExistingOrdersManager`
2. Implement `Manage()` method or `_ManageSingleOrder(Order*)` for existing orders
3. Place in `Libraries/OrderManagers/`

**New Money Manager**:
1. Inherit from `IMoneyManager`
2. Implement `CalculateLots(Order*)` method
3. Place in `Libraries/MoneyManagers/`

**New Market Indicator**:
1. Inherit from `IMarketIndicator`
2. Implement trend and entry point methods
3. Place in `Libraries/MarketIndicators/`

## Error Handling

The codebase uses a custom exception system in `Common.mqh`:
- `ThrowException()` displays alerts and removes the EA
- Specific exception types: `ThrowArgumentException()`, `ThrowNotSupportedException()`
- Interface method stubs throw `ThrowInterfaceNotImplementedException()`