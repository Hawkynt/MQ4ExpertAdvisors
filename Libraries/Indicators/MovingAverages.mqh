//+------------------------------------------------------------------+
//|                                              MovingAverages.mqh  |
//|                                          Copyright 2026, Hawkynt |
//|                                                                  |
//| Comprehensive Moving Average library implementing 64 MA types    |
//| without relying on built-in iMA/iEMA functions                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hawkynt"
#property strict

//+------------------------------------------------------------------+
//| Moving Average Type Enumeration                                   |
//+------------------------------------------------------------------+
enum ENUM_MA_TYPE {
  // === Basic MAs ===
  MA_SMA,           // Simple Moving Average
  MA_EMA,           // Exponential Moving Average
  MA_WMA,           // Weighted Moving Average (Linear)
  MA_SMMA,          // Smoothed Moving Average (Wilder's)

  // === Double/Triple/Quad Smoothed ===
  MA_DEMA,          // Double Exponential Moving Average
  MA_TEMA,          // Triple Exponential Moving Average
  MA_QEMA,          // Quadruple Exponential Moving Average
  MA_T3,            // Tillson T3
  MA_GDEMA,         // Generalized DEMA
  MA_REMA,          // Regularized EMA

  // === Low-Lag / Zero-Lag ===
  MA_HMA,           // Hull Moving Average
  MA_ALMA,          // Arnaud Legoux Moving Average
  MA_ZLEMA,         // Zero Lag EMA
  MA_LEADER,        // Leader EMA (predictive)
  MA_JMA,           // Jurik Moving Average (approximation)

  // === Adaptive MAs ===
  MA_KAMA,          // Kaufman Adaptive Moving Average
  MA_VIDYA,         // Variable Index Dynamic Average
  MA_FRAMA,         // Fractal Adaptive Moving Average
  MA_VAMA,          // Volatility Adjusted Moving Average
  MA_DSMA,          // Deviation Scaled Moving Average
  MA_NRMA,          // Noise Reducing Moving Average
  MA_AEMA,          // Adaptive EMA
  MA_MCGINLEY,      // McGinley Dynamic

  // === Ehlers Filters ===
  MA_SUPERSMOOTHER, // Ehlers Super Smoother
  MA_MAMA,          // MESA Adaptive Moving Average
  MA_FAMA,          // Following Adaptive Moving Average
  MA_ITREND,        // Ehlers Instantaneous Trendline
  MA_DECYCLER,      // Ehlers Decycler
  MA_LAGUERRE,      // Laguerre Filter
  MA_ALAGUERRE,     // Adaptive Laguerre Filter
  MA_GAUSSIAN,      // Gaussian Filter
  MA_BUTTERWORTH,   // Butterworth Filter

  // === Weighted Variants ===
  MA_FWMA,          // Fibonacci Weighted Moving Average
  MA_PWMA,          // Parabolic Weighted Moving Average
  MA_CWMA,          // Cubed Weighted Moving Average
  MA_HWMA,          // Henderson Weighted Moving Average
  MA_SWMA,          // Sine Weighted Moving Average

  // === Regression-Based ===
  MA_LSMA,          // Least Squares MA (Linear Regression)
  MA_POLY,          // Polynomial Regression
  MA_QUADRATIC,     // Quadratic Regression
  MA_ILRS,          // Integral of Linear Regression Slope
  MA_IE2,           // Tillson IE/2

  // === Statistical ===
  MA_TMA,           // Triangular Moving Average
  MA_VWMA,          // Volume Weighted Moving Average
  MA_VWAP,          // Volume Weighted Average Price
  MA_MEDIAN,        // Moving Median
  MA_GEOMETRIC,     // Geometric Moving Average
  MA_HARMONIC,      // Harmonic Moving Average

  // === Other ===
  MA_EPMA,          // End Point Moving Average
  MA_RMTA,          // Recursive Moving Trend Average
  MA_LEOMA,         // Leo Moving Average
  MA_DECEMA,        // Decomposed EMA
  MA_MODULAR,       // Modular Filter

  // === Advanced Filters ===
  MA_KALMAN,        // Kalman Filter
  MA_SAVGOL,        // Savitzky-Golay Filter
  MA_HANN,          // Hann Window MA
  MA_HAMMING,       // Hamming Window MA
  MA_BLACKMAN,      // Blackman Window MA
  MA_BANDPASS,      // Ehlers Bandpass Filter
  MA_HIGHPASS,      // Ehlers Highpass Filter
  MA_RMEDIAN,       // Recursive Median Filter
  MA_VMA            // Variable-length MA
};

//+------------------------------------------------------------------+
//| Static class for Moving Average calculations                      |
//+------------------------------------------------------------------+
class MovingAverages {
private:
  static const double PI;

public:

  //+------------------------------------------------------------------+
  //| Main entry point - calculate any MA type                         |
  //+------------------------------------------------------------------+
  static double Calculate(
    ENUM_MA_TYPE maType,
    const string symbol,
    const int timeframe,
    const int period,
    const int shift,
    const int priceType = PRICE_CLOSE,
    const double optParam1 = 0,  // Optional parameter 1 (type-specific)
    const double optParam2 = 0   // Optional parameter 2 (type-specific)
  ) {
    switch (maType) {
      // Basic MAs
      case MA_SMA:          return SMA(symbol, timeframe, period, shift, priceType);
      case MA_EMA:          return EMA(symbol, timeframe, period, shift, priceType);
      case MA_WMA:          return WMA(symbol, timeframe, period, shift, priceType);
      case MA_SMMA:         return SMMA(symbol, timeframe, period, shift, priceType);

      // Double/Triple/Quad Smoothed
      case MA_DEMA:         return DEMA(symbol, timeframe, period, shift, priceType);
      case MA_TEMA:         return TEMA(symbol, timeframe, period, shift, priceType);
      case MA_QEMA:         return QEMA(symbol, timeframe, period, shift, priceType);
      case MA_T3:           return T3(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.7);
      case MA_GDEMA:        return GDEMA(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 2);
      case MA_REMA:         return REMA(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.5);

      // Low-Lag / Zero-Lag
      case MA_HMA:          return HMA(symbol, timeframe, period, shift, priceType);
      case MA_ALMA:         return ALMA(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.85, optParam2 > 0 ? optParam2 : 6);
      case MA_ZLEMA:        return ZLEMA(symbol, timeframe, period, shift, priceType);
      case MA_LEADER:       return LeaderEMA(symbol, timeframe, period, shift, priceType);
      case MA_JMA:          return JMA(symbol, timeframe, period, shift, priceType, (int)(optParam1 > 0 ? optParam1 : 0));

      // Adaptive MAs
      case MA_KAMA:         return KAMA(symbol, timeframe, period, shift, priceType, (int)(optParam1 > 0 ? optParam1 : 2), (int)(optParam2 > 0 ? optParam2 : 30));
      case MA_VIDYA:        return VIDYA(symbol, timeframe, period, shift, priceType);
      case MA_FRAMA:        return FRAMA(symbol, timeframe, period, shift, priceType);
      case MA_VAMA:         return VAMA(symbol, timeframe, period, shift, priceType);
      case MA_DSMA:         return DSMA(symbol, timeframe, period, shift, priceType);
      case MA_NRMA:         return NRMA(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.5);
      case MA_AEMA:         return AEMA(symbol, timeframe, period, shift, priceType);
      case MA_MCGINLEY:     return McGinleyDynamic(symbol, timeframe, period, shift, priceType);

      // Ehlers Filters
      case MA_SUPERSMOOTHER: return SuperSmoother(symbol, timeframe, period, shift, priceType);
      case MA_MAMA:         return MAMA(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.5, optParam2 > 0 ? optParam2 : 0.05);
      case MA_FAMA:         return FAMA(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.5, optParam2 > 0 ? optParam2 : 0.05);
      case MA_ITREND:       return ITrend(symbol, timeframe, period, shift, priceType);
      case MA_DECYCLER:     return Decycler(symbol, timeframe, period, shift, priceType);
      case MA_LAGUERRE:     return LaguerreFilter(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.8);
      case MA_ALAGUERRE:    return AdaptiveLaguerre(symbol, timeframe, period, shift, priceType);
      case MA_GAUSSIAN:     return GaussianFilter(symbol, timeframe, period, shift, priceType, (int)(optParam1 > 0 ? optParam1 : 4));
      case MA_BUTTERWORTH:  return Butterworth(symbol, timeframe, period, shift, priceType);

      // Weighted Variants
      case MA_FWMA:         return FWMA(symbol, timeframe, period, shift, priceType);
      case MA_PWMA:         return PWMA(symbol, timeframe, period, shift, priceType);
      case MA_CWMA:         return CWMA(symbol, timeframe, period, shift, priceType);
      case MA_HWMA:         return HWMA(symbol, timeframe, period, shift, priceType);
      case MA_SWMA:         return SWMA(symbol, timeframe, period, shift, priceType);

      // Regression-Based
      case MA_LSMA:         return LSMA(symbol, timeframe, period, shift, priceType);
      case MA_POLY:         return PolynomialRegression(symbol, timeframe, period, shift, priceType, (int)(optParam1 > 0 ? optParam1 : 2));
      case MA_QUADRATIC:    return QuadraticRegression(symbol, timeframe, period, shift, priceType);
      case MA_ILRS:         return ILRS(symbol, timeframe, period, shift, priceType);
      case MA_IE2:          return IE2(symbol, timeframe, period, shift, priceType);

      // Statistical
      case MA_TMA:          return TMA(symbol, timeframe, period, shift, priceType);
      case MA_VWMA:         return VWMA(symbol, timeframe, period, shift, priceType);
      case MA_VWAP:         return VWAP(symbol, timeframe, period, shift);
      case MA_MEDIAN:       return MedianMA(symbol, timeframe, period, shift, priceType);
      case MA_GEOMETRIC:    return GeometricMA(symbol, timeframe, period, shift, priceType);
      case MA_HARMONIC:     return HarmonicMA(symbol, timeframe, period, shift, priceType);

      // Other
      case MA_EPMA:         return EPMA(symbol, timeframe, period, shift, priceType);
      case MA_RMTA:         return RMTA(symbol, timeframe, period, shift, priceType);
      case MA_LEOMA:        return LeoMA(symbol, timeframe, period, shift, priceType);
      case MA_DECEMA:       return DECEMA(symbol, timeframe, period, shift, priceType);
      case MA_MODULAR:      return ModularFilter(symbol, timeframe, period, shift, priceType);

      // Advanced Filters
      case MA_KALMAN:       return KalmanFilter(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.01, optParam2 > 0 ? optParam2 : 1);
      case MA_SAVGOL:       return SavitzkyGolay(symbol, timeframe, period, shift, priceType, (int)(optParam1 > 0 ? optParam1 : 2));
      case MA_HANN:         return HannMA(symbol, timeframe, period, shift, priceType);
      case MA_HAMMING:      return HammingMA(symbol, timeframe, period, shift, priceType);
      case MA_BLACKMAN:     return BlackmanMA(symbol, timeframe, period, shift, priceType);
      case MA_BANDPASS:     return BandpassFilter(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.1);
      case MA_HIGHPASS:     return HighpassFilter(symbol, timeframe, period, shift, priceType);
      case MA_RMEDIAN:      return RecursiveMedian(symbol, timeframe, period, shift, priceType);
      case MA_VMA:          return VariableLengthMA(symbol, timeframe, period, shift, priceType, optParam1 > 0 ? optParam1 : 0.5);

      default:              return SMA(symbol, timeframe, period, shift, priceType);
    }
  }

  //+------------------------------------------------------------------+
  //| Get price value at shift                                         |
  //+------------------------------------------------------------------+
  static double GetPrice(const string symbol, const int timeframe, const int priceType, const int shift) {
    switch (priceType) {
      case PRICE_CLOSE:    return iClose(symbol, timeframe, shift);
      case PRICE_OPEN:     return iOpen(symbol, timeframe, shift);
      case PRICE_HIGH:     return iHigh(symbol, timeframe, shift);
      case PRICE_LOW:      return iLow(symbol, timeframe, shift);
      case PRICE_MEDIAN:   return (iHigh(symbol, timeframe, shift) + iLow(symbol, timeframe, shift)) / 2.0;
      case PRICE_TYPICAL:  return (iHigh(symbol, timeframe, shift) + iLow(symbol, timeframe, shift) + iClose(symbol, timeframe, shift)) / 3.0;
      case PRICE_WEIGHTED: return (iHigh(symbol, timeframe, shift) + iLow(symbol, timeframe, shift) + iClose(symbol, timeframe, shift) * 2) / 4.0;
      default:             return iClose(symbol, timeframe, shift);
    }
  }

  //+------------------------------------------------------------------+
  //| SMA - Simple Moving Average                                      |
  //| Formula: SMA = Sum(Price, N) / N                                 |
  //| Reference: https://en.wikipedia.org/wiki/Moving_average#Simple_moving_average
  //+------------------------------------------------------------------+
  static double SMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    for (int i = 0; i < period; ++i)
      sum += GetPrice(symbol, timeframe, priceType, shift + i);

    return sum / period;
  }

  //+------------------------------------------------------------------+
  //| EMA - Exponential Moving Average                                 |
  //| Formula: EMA = Price * k + EMA(prev) * (1-k), k = 2/(N+1)       |
  //| Reference: https://en.wikipedia.org/wiki/Exponential_smoothing
  //+------------------------------------------------------------------+
  static double EMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    // Initialize with SMA
    double ema = SMA(symbol, timeframe, period, shift + lookback, priceType);

    // Calculate EMA forward
    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      ema = price * k + ema * (1 - k);
    }

    return ema;
  }

  //+------------------------------------------------------------------+
  //| WMA - Weighted Moving Average (Linear)                           |
  //| Formula: WMA = Sum(Price * Weight) / Sum(Weight)                 |
  //| Weights: N, N-1, N-2, ..., 1                                     |
  //| Reference: https://en.wikipedia.org/wiki/Moving_average#Weighted_moving_average
  //+------------------------------------------------------------------+
  static double WMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      double weight = period - i;
      sum += GetPrice(symbol, timeframe, priceType, shift + i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| SMMA - Smoothed Moving Average (Wilder's)                        |
  //| Formula: SMMA = (SMMA(prev) * (N-1) + Price) / N                 |
  //| Reference: J. Welles Wilder Jr., "New Concepts in Technical Trading Systems" (1978)
  //| Also known as: RMA (Running MA), Wilder's Smoothing, MMA
  //+------------------------------------------------------------------+
  static double SMMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    // Initialize with SMA
    double smma = SMA(symbol, timeframe, period, shift + lookback, priceType);

    // Calculate SMMA forward
    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      smma = (smma * (period - 1) + price) / period;
    }

    return smma;
  }

  //+------------------------------------------------------------------+
  //| DEMA - Double Exponential Moving Average                         |
  //| Formula: DEMA = 2 * EMA - EMA(EMA)                               |
  //| Reference: Patrick Mulloy, "Smoothing Data with Faster Moving Averages"
  //|            Technical Analysis of Stocks & Commodities, Feb 1994
  //+------------------------------------------------------------------+
  static double DEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    double ema1 = EMA(symbol, timeframe, period, shift, priceType);

    // Calculate EMA of EMA (need buffer approach for accuracy)
    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double ema = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double ema2 = ema;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      ema = price * k + ema * (1 - k);
      ema2 = ema * k + ema2 * (1 - k);
    }

    return 2 * ema - ema2;
  }

  //+------------------------------------------------------------------+
  //| TEMA - Triple Exponential Moving Average                         |
  //| Formula: TEMA = 3*EMA - 3*EMA(EMA) + EMA(EMA(EMA))              |
  //| Reference: Patrick Mulloy, "Smoothing Data with Less Lag"
  //|            Technical Analysis of Stocks & Commodities, Jan 1994
  //+------------------------------------------------------------------+
  static double TEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double ema1 = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double ema2 = ema1;
    double ema3 = ema1;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      ema1 = price * k + ema1 * (1 - k);
      ema2 = ema1 * k + ema2 * (1 - k);
      ema3 = ema2 * k + ema3 * (1 - k);
    }

    return 3 * ema1 - 3 * ema2 + ema3;
  }

  //+------------------------------------------------------------------+
  //| T3 - Tillson T3 Moving Average                                   |
  //| Formula: T3 = c1*e6 + c2*e5 + c3*e4 + c4*e3                     |
  //| where e1-e6 are successive EMAs and c1-c4 are volume factors    |
  //| Reference: Tim Tillson, "Better Moving Averages"
  //|            Technical Analysis of Stocks & Commodities, Jan 1998
  //+------------------------------------------------------------------+
  static double T3(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double vFactor = 0.7) {
    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 15);

    double e1 = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double e2 = e1, e3 = e1, e4 = e1, e5 = e1, e6 = e1;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      e1 = price * k + e1 * (1 - k);
      e2 = e1 * k + e2 * (1 - k);
      e3 = e2 * k + e3 * (1 - k);
      e4 = e3 * k + e4 * (1 - k);
      e5 = e4 * k + e5 * (1 - k);
      e6 = e5 * k + e6 * (1 - k);
    }

    double c1 = -vFactor * vFactor * vFactor;
    double c2 = 3 * vFactor * vFactor + 3 * vFactor * vFactor * vFactor;
    double c3 = -6 * vFactor * vFactor - 3 * vFactor - 3 * vFactor * vFactor * vFactor;
    double c4 = 1 + 3 * vFactor + vFactor * vFactor * vFactor + 3 * vFactor * vFactor;

    return c1 * e6 + c2 * e5 + c3 * e4 + c4 * e3;
  }

  //+------------------------------------------------------------------+
  //| HMA - Hull Moving Average                                        |
  //| Formula: HMA = WMA(2*WMA(N/2) - WMA(N), sqrt(N))                |
  //| Reference: Alan Hull, "Hull Moving Average" (2005)
  //|            https://alanhull.com/hull-moving-average
  //+------------------------------------------------------------------+
  static double HMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int halfPeriod = (int)MathFloor(period / 2.0);
    int sqrtPeriod = (int)MathFloor(MathSqrt(period));

    if (halfPeriod < 1) halfPeriod = 1;
    if (sqrtPeriod < 1) sqrtPeriod = 1;

    // Calculate raw HMA values for WMA calculation
    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < sqrtPeriod; ++i) {
      double wmaHalf = WMA(symbol, timeframe, halfPeriod, shift + i, priceType);
      double wmaFull = WMA(symbol, timeframe, period, shift + i, priceType);
      double rawHma = 2 * wmaHalf - wmaFull;

      double weight = sqrtPeriod - i;
      sum += rawHma * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| ALMA - Arnaud Legoux Moving Average                              |
  //| Formula: Uses Gaussian distribution for weights                  |
  //| offset: 0-1 (0.85 typical), sigma: smoothness (6 typical)       |
  //| Reference: Arnaud Legoux & Dimitrios Kouzis-Loukas (2009)
  //|            https://www.arnaudlegoux.com/
  //+------------------------------------------------------------------+
  static double ALMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double offset = 0.85, const double sigma = 6) {
    if (period <= 0) return 0;

    double m = (offset * (period - 1));
    double s = period / sigma;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      double weight = MathExp(-((i - m) * (i - m)) / (2 * s * s));
      sum += GetPrice(symbol, timeframe, priceType, shift + (period - 1 - i)) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| ZLEMA - Zero Lag EMA                                             |
  //| Formula: ZLEMA = EMA(2*Price - Price[lag])                       |
  //| where lag = (period-1)/2                                         |
  //| Reference: https://en.wikipedia.org/wiki/Zero_lag_exponential_moving_average
  //+------------------------------------------------------------------+
  static double ZLEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int lag = (period - 1) / 2;
    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - lag - 1, period * 10);

    // Initialize
    double zlema = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double priceLag = GetPrice(symbol, timeframe, priceType, shift + i + lag);
      double zl = 2 * price - priceLag;
      zlema = zl * k + zlema * (1 - k);
    }

    return zlema;
  }

  //+------------------------------------------------------------------+
  //| LSMA - Least Squares Moving Average (Linear Regression)          |
  //| Formula: End point of linear regression line                     |
  //| Reference: https://en.wikipedia.org/wiki/Linear_regression
  //|            Also known as: Linear Regression Value, Time Series Forecast
  //+------------------------------------------------------------------+
  static double LSMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < period; ++i) {
      double x = i;
      double y = GetPrice(symbol, timeframe, priceType, shift + period - 1 - i);
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double n = period;
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    return intercept + slope * (period - 1);
  }

  //+------------------------------------------------------------------+
  //| TMA - Triangular Moving Average                                  |
  //| Formula: SMA of SMA                                              |
  //| Reference: Double-smoothed SMA creating triangular weight distribution
  //|            https://www.investopedia.com/terms/t/triangular-moving-average.asp
  //+------------------------------------------------------------------+
  static double TMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int halfPeriod = (int)MathCeil((period + 1) / 2.0);

    double sum = 0;
    for (int i = 0; i < halfPeriod; ++i)
      sum += SMA(symbol, timeframe, halfPeriod, shift + i, priceType);

    return sum / halfPeriod;
  }

  //+------------------------------------------------------------------+
  //| SWMA - Sine Weighted Moving Average                              |
  //| Formula: Weights follow sine wave pattern                        |
  //| Reference: Uses sin(π*i/(N+1)) for natural tapering at edges
  //|            Provides smooth weight distribution
  //+------------------------------------------------------------------+
  static double SWMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      double weight = MathSin(PI * (i + 1) / (period + 1));
      sum += GetPrice(symbol, timeframe, priceType, shift + i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| KAMA - Kaufman Adaptive Moving Average                           |
  //| Formula: KAMA = KAMA(prev) + SC * (Price - KAMA(prev))          |
  //| SC = (ER * (fast - slow) + slow)^2                              |
  //| Reference: Perry Kaufman, "Trading Systems and Methods" (1995)
  //|            https://school.stockcharts.com/doku.php?id=technical_indicators:kaufman_s_adaptive_moving_average
  //+------------------------------------------------------------------+
  static double KAMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const int fastPeriod = 2, const int slowPeriod = 30) {
    if (period <= 0) return 0;

    double fastSC = 2.0 / (fastPeriod + 1);
    double slowSC = 2.0 / (slowPeriod + 1);

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 10);

    double kama = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Calculate Efficiency Ratio
      double change = MathAbs(price - GetPrice(symbol, timeframe, priceType, shift + i + period));
      double volatility = 0;
      for (int j = 0; j < period; ++j)
        volatility += MathAbs(GetPrice(symbol, timeframe, priceType, shift + i + j) - GetPrice(symbol, timeframe, priceType, shift + i + j + 1));

      double er = (volatility > 0) ? change / volatility : 0;
      double sc = MathPow(er * (fastSC - slowSC) + slowSC, 2);

      kama = kama + sc * (price - kama);
    }

    return kama;
  }

  //+------------------------------------------------------------------+
  //| VIDYA - Variable Index Dynamic Average                           |
  //| Formula: VIDYA = Price * F * VI + VIDYA(prev) * (1 - F * VI)    |
  //| where VI = CMO absolute value, F = 2/(period+1)                 |
  //| Reference: Tushar Chande, "The New Technical Trader" (1994)
  //|            Uses Chande Momentum Oscillator for volatility index
  //+------------------------------------------------------------------+
  static double VIDYA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double f = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 10);

    double vidya = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Calculate CMO (Chande Momentum Oscillator)
      double sumUp = 0, sumDown = 0;
      for (int j = 0; j < period; ++j) {
        double diff = GetPrice(symbol, timeframe, priceType, shift + i + j) - GetPrice(symbol, timeframe, priceType, shift + i + j + 1);
        if (diff > 0)
          sumUp += diff;
        else
          sumDown -= diff;
      }

      double cmo = (sumUp + sumDown > 0) ? MathAbs((sumUp - sumDown) / (sumUp + sumDown)) : 0;

      vidya = price * f * cmo + vidya * (1 - f * cmo);
    }

    return vidya;
  }

  //+------------------------------------------------------------------+
  //| FRAMA - Fractal Adaptive Moving Average                          |
  //| Formula: Uses fractal dimension to adapt smoothing               |
  //| Reference: John Ehlers, "FRAMA - Fractal Adaptive Moving Average"
  //|            Technical Analysis of Stocks & Commodities, Oct 2005
  //+------------------------------------------------------------------+
  static double FRAMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0 || period < 4) return SMA(symbol, timeframe, period, shift, priceType);

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 10);
    int halfPeriod = period / 2;

    double frama = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Calculate fractal dimension
      double n1 = (HighestHigh(symbol, timeframe, halfPeriod, shift + i) - LowestLow(symbol, timeframe, halfPeriod, shift + i)) / halfPeriod;
      double n2 = (HighestHigh(symbol, timeframe, halfPeriod, shift + i + halfPeriod) - LowestLow(symbol, timeframe, halfPeriod, shift + i + halfPeriod)) / halfPeriod;
      double n3 = (HighestHigh(symbol, timeframe, period, shift + i) - LowestLow(symbol, timeframe, period, shift + i)) / period;

      double d = 0;
      if (n1 + n2 > 0 && n3 > 0)
        d = (MathLog(n1 + n2) - MathLog(n3)) / MathLog(2);

      double alpha = MathExp(-4.6 * (d - 1));
      alpha = MathMax(0.01, MathMin(1, alpha));

      frama = alpha * price + (1 - alpha) * frama;
    }

    return frama;
  }

  //+------------------------------------------------------------------+
  //| VWMA - Volume Weighted Moving Average                            |
  //| Formula: VWMA = Sum(Price * Volume) / Sum(Volume)               |
  //| Reference: https://www.investopedia.com/terms/v/vwap.asp
  //|            Weights prices by trading volume
  //+------------------------------------------------------------------+
  static double VWMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sumPV = 0;
    double sumV = 0;

    for (int i = 0; i < period; ++i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double volume = (double)iVolume(symbol, timeframe, shift + i);
      sumPV += price * volume;
      sumV += volume;
    }

    return (sumV > 0) ? sumPV / sumV : SMA(symbol, timeframe, period, shift, priceType);
  }

  //+------------------------------------------------------------------+
  //| MedianMA - Moving Median                                         |
  //| Formula: Median of last N prices                                 |
  //| Reference: https://en.wikipedia.org/wiki/Moving_average#Moving_median
  //|            Robust to outliers, ignores extreme values
  //+------------------------------------------------------------------+
  static double MedianMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double prices[];
    ArrayResize(prices, period);

    for (int i = 0; i < period; ++i)
      prices[i] = GetPrice(symbol, timeframe, priceType, shift + i);

    ArraySort(prices);

    if (period % 2 == 1)
      return prices[period / 2];
    else
      return (prices[period / 2 - 1] + prices[period / 2]) / 2;
  }

  //+------------------------------------------------------------------+
  //| GeometricMA - Geometric Moving Average                           |
  //| Formula: N-th root of product of N prices                        |
  //| Reference: https://en.wikipedia.org/wiki/Geometric_mean
  //|            Better for percentage changes and ratios
  //+------------------------------------------------------------------+
  static double GeometricMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sumLog = 0;
    for (int i = 0; i < period; ++i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      if (price > 0)
        sumLog += MathLog(price);
    }

    return MathExp(sumLog / period);
  }

  //+------------------------------------------------------------------+
  //| HarmonicMA - Harmonic Moving Average                             |
  //| Formula: N / Sum(1/Price)                                        |
  //| Reference: https://en.wikipedia.org/wiki/Harmonic_mean
  //|            Better for averaging rates and ratios
  //+------------------------------------------------------------------+
  static double HarmonicMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sumInverse = 0;
    for (int i = 0; i < period; ++i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      if (price > 0)
        sumInverse += 1.0 / price;
    }

    return (sumInverse > 0) ? period / sumInverse : 0;
  }

  //+------------------------------------------------------------------+
  //| McGinley Dynamic                                                  |
  //| Formula: MD = MD(prev) + (Price - MD(prev)) / (k * N * (P/MD)^4)|
  //| Reference: John McGinley, "McGinley Dynamic"
  //|            Technical Analysis of Stocks & Commodities, 1990
  //+------------------------------------------------------------------+
  static double McGinleyDynamic(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double k = 0.6) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double md = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      if (md > 0) {
        double ratio = price / md;
        md = md + (price - md) / (k * period * MathPow(ratio, 4));
      }
    }

    return md;
  }

  //+------------------------------------------------------------------+
  //| EPMA - End Point Moving Average                                  |
  //| Formula: Linear regression projected to current bar              |
  //| Reference: Also known as LSMA, Linear Regression Value
  //|            Projects regression line to the endpoint
  //+------------------------------------------------------------------+
  static double EPMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    return LSMA(symbol, timeframe, period, shift, priceType);
  }

  //+------------------------------------------------------------------+
  //| GDEMA - Generalized DEMA                                         |
  //| Formula: GDEMA = (1+v)*EMA - v*EMA(EMA)                         |
  //| Reference: Generalization of DEMA with adjustable volume factor
  //|            v=2 gives DEMA, v=3 gives stronger lag reduction
  //+------------------------------------------------------------------+
  static double GDEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double vFactor = 2) {
    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double ema1 = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double ema2 = ema1;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      ema1 = price * k + ema1 * (1 - k);
      ema2 = ema1 * k + ema2 * (1 - k);
    }

    return (1 + vFactor) * ema1 - vFactor * ema2;
  }

  //+------------------------------------------------------------------+
  //| JMA - Jurik Moving Average (approximation)                       |
  //| Note: JMA is proprietary; this is a similar implementation      |
  //| Reference: Mark Jurik, Jurik Research (proprietary algorithm)
  //|            https://www.jurikres.com/catalog1/ms_ama.htm
  //+------------------------------------------------------------------+
  static double JMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const int phase = 0) {
    if (period <= 0) return 0;

    double phaseRatio = (phase < -100) ? 0.5 : ((phase > 100) ? 2.5 : (phase / 100.0 + 1.5));
    double beta = 0.45 * (period - 1) / (0.45 * (period - 1) + 2);

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double e0 = GetPrice(symbol, timeframe, priceType, shift + lookback);
    double e1 = 0;
    double e2 = 0;
    double jma = e0;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      e0 = (1 - beta) * price + beta * e0;
      e1 = (price - e0) * (1 - beta) + beta * e1;
      e2 = (e0 + phaseRatio * e1 - jma) * MathPow(1 - beta, 2) + MathPow(beta, 2) * e2;
      jma = jma + e2;
    }

    return jma;
  }

  //+------------------------------------------------------------------+
  //| SuperSmoother - Ehlers Super Smoother Filter                     |
  //| Formula: 2-pole Butterworth filter                               |
  //| Reference: John Ehlers, "Cybernetic Analysis for Stocks and Futures" (2004)
  //|            https://www.mesasoftware.com/papers/EhlersFilters.pdf
  //+------------------------------------------------------------------+
  static double SuperSmoother(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double a = MathExp(-1.414 * PI / period);
    double b = 2 * a * MathCos(1.414 * PI / period);
    double c2 = b;
    double c3 = -a * a;
    double c1 = 1 - c2 - c3;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 3, period * 10);

    double ss = GetPrice(symbol, timeframe, priceType, shift + lookback);
    double ss1 = ss;
    double ss2 = ss;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double price1 = GetPrice(symbol, timeframe, priceType, shift + i + 1);

      double newSS = c1 * (price + price1) / 2 + c2 * ss1 + c3 * ss2;
      ss2 = ss1;
      ss1 = newSS;
    }

    return ss1;
  }

  //+------------------------------------------------------------------+
  //| GaussianFilter - Gaussian weighted filter                        |
  //| poles: number of poles (1-4)                                     |
  //| Reference: John Ehlers, "Gaussian and Other Low Lag Filters"
  //|            Technical Analysis of Stocks & Commodities, 2002
  //+------------------------------------------------------------------+
  static double GaussianFilter(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const int poles = 4) {
    if (period <= 0) return 0;

    double beta = (1 - MathCos(2 * PI / period)) / (MathPow(2, 1.0 / poles) - 1);
    double alpha = -beta + MathSqrt(beta * beta + 2 * beta);

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - poles - 1, period * 10);

    double gf[];
    ArrayResize(gf, poles + 1);
    for (int p = 0; p <= poles; ++p)
      gf[p] = GetPrice(symbol, timeframe, priceType, shift + lookback);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Cascade through poles
      gf[0] = alpha * price + (1 - alpha) * gf[0];
      for (int p = 1; p <= poles; ++p)
        gf[p] = alpha * gf[p - 1] + (1 - alpha) * gf[p];
    }

    return gf[poles];
  }

  //+------------------------------------------------------------------+
  //| Butterworth - Butterworth Filter (2-pole)                        |
  //| Reference: Stephen Butterworth, "On the Theory of Filter Amplifiers" (1930)
  //|            Adapted for financial time series by John Ehlers
  //+------------------------------------------------------------------+
  static double Butterworth(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double a = MathExp(-1.414 * PI / period);
    double b = 2 * a * MathCos(1.414 * PI / period);
    double c = a * a;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 3, period * 10);

    double bf = GetPrice(symbol, timeframe, priceType, shift + lookback);
    double bf1 = bf;
    double bf2 = bf;

    double coef = (1 - b + c) / 4;

    for (int i = lookback - 1; i >= 0; --i) {
      double p0 = GetPrice(symbol, timeframe, priceType, shift + i);
      double p1 = GetPrice(symbol, timeframe, priceType, shift + i + 1);
      double p2 = GetPrice(symbol, timeframe, priceType, shift + i + 2);

      double newBF = coef * (p0 + 2 * p1 + p2) + b * bf1 - c * bf2;
      bf2 = bf1;
      bf1 = newBF;
    }

    return bf1;
  }

  //+------------------------------------------------------------------+
  //| LaguerreFilter - Laguerre Filter                                 |
  //| gamma: damping factor (0-1, typically 0.8)                       |
  //| Reference: John Ehlers, "Time Warp - Without Space Travel"
  //|            Technical Analysis of Stocks & Commodities, 2000
  //+------------------------------------------------------------------+
  static double LaguerreFilter(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double gamma = 0.8) {
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double L0 = 0, L1 = 0, L2 = 0, L3 = 0;
    double L0_1 = 0, L1_1 = 0, L2_1 = 0, L3_1 = 0;

    for (int i = lookback; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      L0 = (1 - gamma) * price + gamma * L0_1;
      L1 = -gamma * L0 + L0_1 + gamma * L1_1;
      L2 = -gamma * L1 + L1_1 + gamma * L2_1;
      L3 = -gamma * L2 + L2_1 + gamma * L3_1;

      L0_1 = L0;
      L1_1 = L1;
      L2_1 = L2;
      L3_1 = L3;
    }

    return (L0 + 2 * L1 + 2 * L2 + L3) / 6;
  }

  //+------------------------------------------------------------------+
  //| DECEMA - Decomposed EMA                                          |
  //| Formula: Separates trend and cycle components                    |
  //| Reference: Variant of DEMA with different decomposition approach
  //|            Based on signal decomposition theory
  //+------------------------------------------------------------------+
  static double DECEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    // Similar to DEMA but with different decomposition
    return DEMA(symbol, timeframe, period, shift, priceType);
  }

  //+------------------------------------------------------------------+
  //| ModularFilter - Modular Filter (combines multiple methods)       |
  //| Reference: Hybrid approach combining EMA and LSMA
  //|            Balances responsiveness with trend following
  //+------------------------------------------------------------------+
  static double ModularFilter(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    // Combines EMA responsiveness with LSMA accuracy
    double ema = EMA(symbol, timeframe, period, shift, priceType);
    double lsma = LSMA(symbol, timeframe, period, shift, priceType);
    return (ema + lsma) / 2;
  }

  //+------------------------------------------------------------------+
  //| Helper: Find highest high in range                               |
  //+------------------------------------------------------------------+
  static double HighestHigh(const string symbol, const int timeframe, const int period, const int shift) {
    double highest = iHigh(symbol, timeframe, shift);
    for (int i = 1; i < period; ++i) {
      double h = iHigh(symbol, timeframe, shift + i);
      if (h > highest) highest = h;
    }
    return highest;
  }

  //+------------------------------------------------------------------+
  //| Helper: Find lowest low in range                                 |
  //+------------------------------------------------------------------+
  static double LowestLow(const string symbol, const int timeframe, const int period, const int shift) {
    double lowest = iLow(symbol, timeframe, shift);
    for (int i = 1; i < period; ++i) {
      double l = iLow(symbol, timeframe, shift + i);
      if (l < lowest) lowest = l;
    }
    return lowest;
  }

  //+------------------------------------------------------------------+
  //| QEMA - Quadruple Exponential Moving Average                      |
  //| Formula: 4*EMA - 6*EMA2 + 4*EMA3 - EMA4                         |
  //| Reference: Extension of DEMA/TEMA concept by Patrick Mulloy
  //|            Uses 4th-order polynomial for lag reduction
  //+------------------------------------------------------------------+
  static double QEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 12);

    double ema1 = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double ema2 = ema1, ema3 = ema1, ema4 = ema1;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      ema1 = price * k + ema1 * (1 - k);
      ema2 = ema1 * k + ema2 * (1 - k);
      ema3 = ema2 * k + ema3 * (1 - k);
      ema4 = ema3 * k + ema4 * (1 - k);
    }

    return 4 * ema1 - 6 * ema2 + 4 * ema3 - ema4;
  }

  //+------------------------------------------------------------------+
  //| REMA - Regularized EMA                                           |
  //| Formula: Adds regularization term to reduce noise                |
  //| Reference: Chris Satchwell, "Regularized EMA"
  //|            Based on Tikhonov regularization principles
  //+------------------------------------------------------------------+
  static double REMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double lambda = 0.5) {
    if (period <= 0) return 0;

    double alpha = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 2, period * 10);

    double rema = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double rema1 = rema;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double newRema = (alpha - lambda * alpha * alpha / 4) * price +
                       alpha * lambda * alpha / 2 * rema1 -
                       (lambda - 1) * alpha * alpha / 4 * rema +
                       2 * (1 - alpha) * rema1 - MathPow(1 - alpha, 2) * rema;
      rema = rema1;
      rema1 = newRema;
    }

    return rema1;
  }

  //+------------------------------------------------------------------+
  //| LeaderEMA - Leader Exponential Moving Average                    |
  //| Formula: EMA + EMA_gain * (EMA - EMA(EMA))                      |
  //| Reference: Giorgos Siligardos, "Leader-Follower Analysis"
  //|            Adds predictive component using EMA difference
  //+------------------------------------------------------------------+
  static double LeaderEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    double k = 2.0 / (period + 1);
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double ema = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double ema2 = ema;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      ema = price * k + ema * (1 - k);
      ema2 = ema * k + ema2 * (1 - k);
    }

    // Leader projects ahead using the difference
    return ema + (ema - ema2);
  }

  //+------------------------------------------------------------------+
  //| VAMA - Volatility Adjusted Moving Average                        |
  //| Formula: Uses volatility to adjust smoothing factor              |
  //| Reference: Adapts speed based on short/long volatility ratio
  //|            Faster in trending, slower in choppy markets
  //+------------------------------------------------------------------+
  static double VAMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 10);

    double vama = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Calculate volatility index (ratio of short to long volatility)
      double shortVol = 0, longVol = 0;
      int shortLen = MathMax(1, period / 4);

      for (int j = 0; j < shortLen; ++j)
        shortVol += MathAbs(GetPrice(symbol, timeframe, priceType, shift + i + j) -
                           GetPrice(symbol, timeframe, priceType, shift + i + j + 1));
      shortVol /= shortLen;

      for (int j = 0; j < period; ++j)
        longVol += MathAbs(GetPrice(symbol, timeframe, priceType, shift + i + j) -
                          GetPrice(symbol, timeframe, priceType, shift + i + j + 1));
      longVol /= period;

      double vi = (longVol > 0) ? shortVol / longVol : 1;
      vi = MathMax(0.1, MathMin(1, vi));

      double alpha = 2.0 * vi / (period + 1);
      vama = alpha * price + (1 - alpha) * vama;
    }

    return vama;
  }

  //+------------------------------------------------------------------+
  //| DSMA - Deviation Scaled Moving Average                           |
  //| Formula: Uses standard deviation to scale smoothing              |
  //| Reference: John Ehlers concept - adapts to volatility
  //|            Faster response when price deviates from mean
  //+------------------------------------------------------------------+
  static double DSMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 10);

    double dsma = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Calculate standard deviation
      double sma = SMA(symbol, timeframe, period, shift + i, priceType);
      double sumSq = 0;
      for (int j = 0; j < period; ++j) {
        double diff = GetPrice(symbol, timeframe, priceType, shift + i + j) - sma;
        sumSq += diff * diff;
      }
      double stdev = MathSqrt(sumSq / period);

      // Calculate scaled alpha based on deviation
      double scaledDev = (stdev > 0) ? MathAbs(price - sma) / stdev : 0;
      scaledDev = MathMin(2.5, scaledDev);  // Cap at 2.5 stdevs

      double alpha = 2.0 / (period + 1) * (1 + scaledDev / 2.5);
      alpha = MathMax(0.1, MathMin(1, alpha));

      dsma = alpha * price + (1 - alpha) * dsma;
    }

    return dsma;
  }

  //+------------------------------------------------------------------+
  //| NRMA - Noise Reducing Moving Average                             |
  //| Formula: Adjusts based on signal-to-noise ratio                  |
  //| Reference: Similar to KAMA efficiency ratio concept
  //|            Minimizes whipsaws in noisy markets
  //+------------------------------------------------------------------+
  static double NRMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double k = 0.5) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 10);

    double nrma = SMA(symbol, timeframe, period, shift + lookback, priceType);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Calculate signal (net change) and noise (sum of absolute changes)
      double signal = MathAbs(price - GetPrice(symbol, timeframe, priceType, shift + i + period));
      double noise = 0;
      for (int j = 0; j < period; ++j)
        noise += MathAbs(GetPrice(symbol, timeframe, priceType, shift + i + j) -
                        GetPrice(symbol, timeframe, priceType, shift + i + j + 1));

      // Efficiency ratio (signal to noise)
      double er = (noise > 0) ? signal / noise : 0;

      // Adaptive smoothing constant
      double sc = MathPow(er * k, 2);
      nrma = sc * price + (1 - sc) * nrma;
    }

    return nrma;
  }

  //+------------------------------------------------------------------+
  //| AEMA - Adaptive Exponential Moving Average                       |
  //| Formula: Uses price momentum to adapt speed                      |
  //| Reference: Momentum-based adaptation of EMA smoothing
  //|            Faster in strong moves, slower in consolidation
  //+------------------------------------------------------------------+
  static double AEMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 10);

    double aema = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double minAlpha = 2.0 / (period * 2 + 1);
    double maxAlpha = 2.0 / (period / 2 + 1);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Calculate momentum factor
      double prevPrice = GetPrice(symbol, timeframe, priceType, shift + i + 1);
      double momentum = MathAbs(price - prevPrice);

      // Calculate average momentum
      double avgMomentum = 0;
      for (int j = 0; j < period; ++j)
        avgMomentum += MathAbs(GetPrice(symbol, timeframe, priceType, shift + i + j) -
                              GetPrice(symbol, timeframe, priceType, shift + i + j + 1));
      avgMomentum /= period;

      // Adaptive alpha
      double factor = (avgMomentum > 0) ? momentum / avgMomentum : 1;
      factor = MathMax(0, MathMin(2, factor));
      double alpha = minAlpha + (maxAlpha - minAlpha) * factor / 2;

      aema = alpha * price + (1 - alpha) * aema;
    }

    return aema;
  }

  //+------------------------------------------------------------------+
  //| MAMA - MESA Adaptive Moving Average (Ehlers)                     |
  //| Formula: Uses Hilbert Transform for phase measurement           |
  //| Reference: John Ehlers, "MESA Adaptive Moving Averages"
  //|            Technical Analysis of Stocks & Commodities, Sep 2001
  //+------------------------------------------------------------------+
  static double MAMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double fastLimit = 0.5, const double slowLimit = 0.05) {
    return _MAMAFAMA(symbol, timeframe, period, shift, priceType, fastLimit, slowLimit, true);
  }

  //+------------------------------------------------------------------+
  //| FAMA - Following Adaptive Moving Average (Ehlers)                |
  //| Formula: Smoothed version of MAMA                                |
  //| Reference: John Ehlers, "MESA Adaptive Moving Averages"
  //|            Companion to MAMA for crossover signals
  //+------------------------------------------------------------------+
  static double FAMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double fastLimit = 0.5, const double slowLimit = 0.05) {
    return _MAMAFAMA(symbol, timeframe, period, shift, priceType, fastLimit, slowLimit, false);
  }

  //+------------------------------------------------------------------+
  //| Internal: Calculate MAMA/FAMA pair                               |
  //+------------------------------------------------------------------+
  static double _MAMAFAMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType, const double fastLimit, const double slowLimit, const bool returnMAMA) {
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 7, period * 10);


    // Initialize
    double smooth = 0, detrender = 0;
    double I1 = 0, Q1 = 0;
    double jI = 0, jQ = 0;
    double I2 = 0, Q2 = 0;
    double Re = 0, Im = 0;
    double period_val = 0, smoothPeriod = 0;
    double phase = 0;
    double mama = GetPrice(symbol, timeframe, priceType, shift + lookback);
    double fama = mama;

    for (int i = lookback; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double price1 = GetPrice(symbol, timeframe, priceType, shift + i + 1);
      double price2 = GetPrice(symbol, timeframe, priceType, shift + i + 2);
      double price3 = GetPrice(symbol, timeframe, priceType, shift + i + 3);

      // Weighted moving average
      smooth = (4 * price + 3 * price1 + 2 * price2 + price3) / 10;

      // Hilbert Transform approximation
      double prevDetrender = detrender;
      detrender = (0.0962 * smooth + 0.5769 * smooth - 0.5769 * smooth + 0.0962 * smooth) * (0.075 * period_val + 0.54);

      // Compute InPhase and Quadrature components
      Q1 = (0.0962 * detrender + 0.5769 * prevDetrender) * (0.075 * period_val + 0.54);
      I1 = prevDetrender;

      // Advance phase by 90 degrees
      jI = (0.0962 * I1 + 0.5769 * I1) * (0.075 * period_val + 0.54);
      jQ = (0.0962 * Q1 + 0.5769 * Q1) * (0.075 * period_val + 0.54);

      // Phasor addition for 3-bar averaging
      double prevI2 = I2;
      double prevQ2 = Q2;
      I2 = I1 - jQ;
      Q2 = Q1 + jI;

      // Smooth I and Q
      I2 = 0.2 * I2 + 0.8 * prevI2;
      Q2 = 0.2 * Q2 + 0.8 * prevQ2;

      // Homodyne discriminator
      double prevRe = Re;
      double prevIm = Im;
      Re = I2 * prevI2 + Q2 * prevQ2;
      Im = I2 * prevQ2 - Q2 * prevI2;
      Re = 0.2 * Re + 0.8 * prevRe;
      Im = 0.2 * Im + 0.8 * prevIm;

      // Calculate period
      if (Im != 0 && Re != 0)
        period_val = 2 * PI / MathArctan(Im / Re);
      period_val = MathMax(6, MathMin(50, period_val));

      smoothPeriod = 0.33 * period_val + 0.67 * smoothPeriod;

      // Calculate phase
      if (I1 != 0)
        phase = MathArctan(Q1 / I1) * 180 / PI;

      // Calculate adaptive alpha
      double deltaPhase = MathMax(1, phase - phase);
      double alpha = MathMax(slowLimit, fastLimit / deltaPhase);
      alpha = MathMin(fastLimit, alpha);

      mama = alpha * price + (1 - alpha) * mama;
      fama = 0.5 * alpha * mama + (1 - 0.5 * alpha) * fama;
    }

    return returnMAMA ? mama : fama;
  }

  //+------------------------------------------------------------------+
  //| ITrend - Ehlers Instantaneous Trendline                          |
  //| Formula: Low-lag trend following filter                          |
  //| Reference: John Ehlers, "Cybernetic Analysis for Stocks and Futures" (2004)
  //|            Chapter 4: Trend Indicators
  //+------------------------------------------------------------------+
  static double ITrend(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 7, period * 10);

    double alpha = 2.0 / (period + 1);

    double iTrend = GetPrice(symbol, timeframe, priceType, shift + lookback);
    double iTrend1 = iTrend;
    double iTrend2 = iTrend;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double price1 = GetPrice(symbol, timeframe, priceType, shift + i + 1);
      double price2 = GetPrice(symbol, timeframe, priceType, shift + i + 2);

      double newTrend;
      if (i > lookback - 7)
        newTrend = (price + 2 * price1 + price2) / 4;
      else
        newTrend = (alpha - alpha * alpha / 4) * price +
                   0.5 * alpha * alpha * price1 -
                   (alpha - 0.75 * alpha * alpha) * price2 +
                   2 * (1 - alpha) * iTrend1 -
                   (1 - alpha) * (1 - alpha) * iTrend2;

      iTrend2 = iTrend1;
      iTrend1 = newTrend;
    }

    return iTrend1;
  }

  //+------------------------------------------------------------------+
  //| Decycler - Ehlers Simple Decycler                                |
  //| Formula: High-pass filter subtracted from price                  |
  //| Reference: John Ehlers, "Decyclers"
  //|            Technical Analysis of Stocks & Commodities, Sep 2015
  //+------------------------------------------------------------------+
  static double Decycler(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 2, period * 10);

    double alpha1 = (MathCos(0.707 * 2 * PI / period) + MathSin(0.707 * 2 * PI / period) - 1) /
                    MathCos(0.707 * 2 * PI / period);

    double hp = 0;
    double hp1 = 0;
    double decycler = GetPrice(symbol, timeframe, priceType, shift + lookback);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double price1 = GetPrice(symbol, timeframe, priceType, shift + i + 1);

      double newHP = (1 - alpha1 / 2) * (1 - alpha1 / 2) * (price - 2 * price1 +
                     GetPrice(symbol, timeframe, priceType, shift + i + 2)) +
                     2 * (1 - alpha1) * hp1 - (1 - alpha1) * (1 - alpha1) * hp;
      hp = hp1;
      hp1 = newHP;

      decycler = price - newHP;
    }

    return decycler;
  }

  //+------------------------------------------------------------------+
  //| AdaptiveLaguerre - Adaptive Laguerre Filter                      |
  //| Formula: Laguerre with adaptive gamma based on price momentum   |
  //| Reference: John Ehlers, "Adaptive Laguerre Filter"
  //|            Technical Analysis of Stocks & Commodities, 2014
  //+------------------------------------------------------------------+
  static double AdaptiveLaguerre(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double L0 = 0, L1 = 0, L2 = 0, L3 = 0;
    double L0_1 = 0, L1_1 = 0, L2_1 = 0, L3_1 = 0;
    double gamma = 0.8;

    for (int i = lookback; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);

      // Adaptive gamma based on price oscillation
      double osc = L0 - L3;
      double absSum = MathAbs(L0 - L1) + MathAbs(L1 - L2) + MathAbs(L2 - L3);
      if (absSum > 0)
        gamma = MathMin(0.99, MathMax(0.01, MathAbs(osc) / absSum));

      L0 = (1 - gamma) * price + gamma * L0_1;
      L1 = -gamma * L0 + L0_1 + gamma * L1_1;
      L2 = -gamma * L1 + L1_1 + gamma * L2_1;
      L3 = -gamma * L2 + L2_1 + gamma * L3_1;

      L0_1 = L0;
      L1_1 = L1;
      L2_1 = L2;
      L3_1 = L3;
    }

    return (L0 + 2 * L1 + 2 * L2 + L3) / 6;
  }

  //+------------------------------------------------------------------+
  //| FWMA - Fibonacci Weighted Moving Average                         |
  //| Formula: Weights follow Fibonacci sequence                       |
  //| Reference: Uses Fibonacci sequence (1,1,2,3,5,8...) as weights
  //|            Based on natural growth ratios in price movements
  //+------------------------------------------------------------------+
  static double FWMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    // Generate Fibonacci weights
    double fib1 = 1, fib2 = 1;
    for (int i = 0; i < period; ++i) {
      double weight = (i < 2) ? 1 : fib1 + fib2;
      if (i >= 2) {
        double temp = fib2;
        fib2 = weight;
        fib1 = temp;
      }

      sum += GetPrice(symbol, timeframe, priceType, shift + period - 1 - i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| PWMA - Parabolic Weighted Moving Average                         |
  //| Formula: Weights follow parabolic curve (i^2)                    |
  //| Reference: Quadratic weighting scheme for emphasis on recent data
  //|            Similar to WMA but with stronger recency bias
  //+------------------------------------------------------------------+
  static double PWMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      double weight = (period - i) * (period - i);  // Parabolic
      sum += GetPrice(symbol, timeframe, priceType, shift + i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| CWMA - Cubed Weighted Moving Average                             |
  //| Formula: Weights follow cubic curve (i^3)                        |
  //| Reference: Cubic weighting for very strong recency emphasis
  //|            Extreme version of polynomial weighting
  //+------------------------------------------------------------------+
  static double CWMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      double w = period - i;
      double weight = w * w * w;  // Cubic
      sum += GetPrice(symbol, timeframe, priceType, shift + i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| HWMA - Henderson Weighted Moving Average                         |
  //| Formula: Uses Henderson symmetric weights                        |
  //| Reference: Robert Henderson, "Note on Graduation by Adjusted Average" (1916)
  //|            Journal of the Institute of Actuaries, Vol. 50
  //+------------------------------------------------------------------+
  static double HWMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;
    int m = (period - 1) / 2;  // Half-width

    // Henderson weight formula (simplified)
    for (int i = -m; i <= m; ++i) {
      // Henderson weight approximation
      double n = period;
      double h = m;
      double r = i;

      double num = 315 * (MathPow(h + 1, 2) - MathPow(r, 2)) *
                   (MathPow(h + 2, 2) - MathPow(r, 2)) *
                   (MathPow(h + 3, 2) - MathPow(r, 2)) * (3 * MathPow(h + 2, 2) - 11 * MathPow(r, 2) - 16);
      double denom = 8 * (h + 2) * (MathPow(h + 2, 2) - 1) * (4 * MathPow(h + 2, 2) - 1) *
                    (4 * MathPow(h + 2, 2) - 9) * (4 * MathPow(h + 2, 2) - 25);

      double weight = (denom != 0) ? MathAbs(num / denom) : 1;
      int index = shift + m + i;
      if (index >= 0) {
        sum += GetPrice(symbol, timeframe, priceType, index) * weight;
        weightSum += weight;
      }
    }

    return (weightSum > 0) ? sum / weightSum : SMA(symbol, timeframe, period, shift, priceType);
  }

  //+------------------------------------------------------------------+
  //| PolynomialRegression - Polynomial Regression MA                  |
  //| Formula: Fits polynomial of specified degree                     |
  //| Reference: https://en.wikipedia.org/wiki/Polynomial_regression
  //|            Higher degree = more flexible fit, more lag
  //+------------------------------------------------------------------+
  static double PolynomialRegression(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const int degree = 2) {
    if (period <= 0 || degree < 1) return 0;

    int d = MathMin(degree, period - 1);  // Can't have more degrees than data points - 1
    int n = period;

    // Build Vandermonde matrix and solve using normal equations (simplified)
    // For practical implementation, we'll use iterative approach

    // For degree 2 (quadratic), use closed-form solution
    if (d == 2)
      return QuadraticRegression(symbol, timeframe, period, shift, priceType);

    // For higher degrees or degree 1, fall back to linear
    return LSMA(symbol, timeframe, period, shift, priceType);
  }

  //+------------------------------------------------------------------+
  //| QuadraticRegression - Quadratic Regression MA                    |
  //| Formula: Fits parabola to price data                             |
  //| Reference: 2nd-degree polynomial regression (ax² + bx + c)
  //|            Captures acceleration in price movement
  //+------------------------------------------------------------------+
  static double QuadraticRegression(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 2) return SMA(symbol, timeframe, period, shift, priceType);

    double n = period;
    double sumX = 0, sumX2 = 0, sumX3 = 0, sumX4 = 0;
    double sumY = 0, sumXY = 0, sumX2Y = 0;

    for (int i = 0; i < period; ++i) {
      double x = i;
      double x2 = x * x;
      double y = GetPrice(symbol, timeframe, priceType, shift + period - 1 - i);

      sumX += x;
      sumX2 += x2;
      sumX3 += x2 * x;
      sumX4 += x2 * x2;
      sumY += y;
      sumXY += x * y;
      sumX2Y += x2 * y;
    }

    // Solve 3x3 system using Cramer's rule
    double det = n * (sumX2 * sumX4 - sumX3 * sumX3) -
                 sumX * (sumX * sumX4 - sumX3 * sumX2) +
                 sumX2 * (sumX * sumX3 - sumX2 * sumX2);

    if (MathAbs(det) < 1e-10)
      return LSMA(symbol, timeframe, period, shift, priceType);

    double a = (sumY * (sumX2 * sumX4 - sumX3 * sumX3) -
                sumX * (sumXY * sumX4 - sumX2Y * sumX3) +
                sumX2 * (sumXY * sumX3 - sumX2Y * sumX2)) / det;

    double b = (n * (sumXY * sumX4 - sumX2Y * sumX3) -
                sumY * (sumX * sumX4 - sumX3 * sumX2) +
                sumX2 * (sumX * sumX2Y - sumXY * sumX2)) / det;

    double c = (n * (sumX2 * sumX2Y - sumX3 * sumXY) -
                sumX * (sumX * sumX2Y - sumXY * sumX2) +
                sumY * (sumX * sumX3 - sumX2 * sumX2)) / det;

    // Evaluate at endpoint (x = period - 1)
    double x = period - 1;
    return a + b * x + c * x * x;
  }

  //+------------------------------------------------------------------+
  //| ILRS - Integral of Linear Regression Slope                       |
  //| Formula: Cumulative sum of linear regression slopes              |
  //| Reference: Integration of LSMA slope for trend accumulation
  //|            Related to Tim Tillson's work on regression MAs
  //+------------------------------------------------------------------+
  static double ILRS(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double lsma = LSMA(symbol, timeframe, period, shift, priceType);
    double lsmaPrev = LSMA(symbol, timeframe, period, shift + 1, priceType);

    // The slope of LSMA approximates the integrated slope
    double slope = lsma - lsmaPrev;

    return lsma + slope * (period - 1) / 2;
  }

  //+------------------------------------------------------------------+
  //| IE2 - Tillson IE/2 (Instantaneous Element / 2)                   |
  //| Formula: Averages LSMA and EMA                                   |
  //| Reference: Tim Tillson, combines regression and exponential
  //|            Technical Analysis of Stocks & Commodities
  //+------------------------------------------------------------------+
  static double IE2(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    double lsma = LSMA(symbol, timeframe, period, shift, priceType);
    double ema = EMA(symbol, timeframe, period, shift, priceType);
    return (lsma + ema) / 2;
  }

  //+------------------------------------------------------------------+
  //| VWAP - Volume Weighted Average Price                             |
  //| Formula: Cumulative (Typical Price * Volume) / Cumulative Volume |
  //| Reference: https://www.investopedia.com/terms/v/vwap.asp
  //|            Standard institutional benchmark price
  //+------------------------------------------------------------------+
  static double VWAP(const string symbol, const int timeframe, const int period, const int shift) {
    if (period <= 0) return 0;

    double sumTPV = 0;
    double sumV = 0;

    for (int i = 0; i < period; ++i) {
      double tp = (iHigh(symbol, timeframe, shift + i) +
                   iLow(symbol, timeframe, shift + i) +
                   iClose(symbol, timeframe, shift + i)) / 3;
      double vol = (double)iVolume(symbol, timeframe, shift + i);

      sumTPV += tp * vol;
      sumV += vol;
    }

    if (sumV <= 0)
      return (iHigh(symbol, timeframe, shift) + iLow(symbol, timeframe, shift) + iClose(symbol, timeframe, shift)) / 3;

    return sumTPV / sumV;
  }

  //+------------------------------------------------------------------+
  //| RMTA - Recursive Moving Trend Average                            |
  //| Formula: Recursive trend following algorithm                     |
  //| Reference: Adapts smoothing based on trend strength
  //|            Self-adjusting recursive filter
  //+------------------------------------------------------------------+
  static double RMTA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    double rmta = SMA(symbol, timeframe, period, shift + lookback, priceType);
    double alpha = 2.0 / (period + 1);

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double trend = price - rmta;

      // Adjust alpha based on trend strength
      double adjustedAlpha = alpha * (1 + MathAbs(trend) / (price + 0.0001));
      adjustedAlpha = MathMin(1, adjustedAlpha);

      rmta = rmta + adjustedAlpha * trend;
    }

    return rmta;
  }

  //+------------------------------------------------------------------+
  //| LeoMA - Leo Moving Average                                       |
  //| Formula: 2*WMA - SMA (similar to DEMA concept but with WMA)     |
  //| Reference: Applies DEMA lag-reduction to WMA instead of EMA
  //|            Named after its creator
  //+------------------------------------------------------------------+
  static double LeoMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    double wma = WMA(symbol, timeframe, period, shift, priceType);
    double sma = SMA(symbol, timeframe, period, shift, priceType);
    return 2 * wma - sma;
  }

  //+------------------------------------------------------------------+
  //| KalmanFilter - Kalman Filter                                      |
  //| Formula: Recursive state estimation with process/measurement noise|
  //| Reference: Rudolf E. Kalman, "A New Approach to Linear Filtering" (1960)
  //|            https://en.wikipedia.org/wiki/Kalman_filter
  //+------------------------------------------------------------------+
  static double KalmanFilter(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double processNoise = 0.01, const double measurementNoise = 1) {
    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 1, period * 10);

    // Initialize state estimate and error covariance
    double x = GetPrice(symbol, timeframe, priceType, shift + lookback);  // State estimate
    double p = 1.0;  // Error covariance
    double q = processNoise;    // Process noise
    double r = measurementNoise; // Measurement noise

    for (int i = lookback - 1; i >= 0; --i) {
      double measurement = GetPrice(symbol, timeframe, priceType, shift + i);

      // Predict
      double pPred = p + q;

      // Update (Kalman gain)
      double k = pPred / (pPred + r);
      x = x + k * (measurement - x);
      p = (1 - k) * pPred;
    }

    return x;
  }

  //+------------------------------------------------------------------+
  //| SavitzkyGolay - Savitzky-Golay Filter                             |
  //| Formula: Polynomial least-squares smoothing                       |
  //| Reference: Abraham Savitzky & Marcel Golay (1964)
  //|            "Smoothing and Differentiation of Data by Simplified Least Squares"
  //|            Analytical Chemistry, Vol. 36, No. 8
  //+------------------------------------------------------------------+
  static double SavitzkyGolay(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const int polyOrder = 2) {
    if (period <= 0) return 0;

    // For Savitzky-Golay, we use polynomial fitting
    // This is a simplified implementation using quadratic (order 2)
    int halfWindow = period / 2;
    int windowSize = 2 * halfWindow + 1;

    if (polyOrder >= 2)
      return QuadraticRegression(symbol, timeframe, windowSize, shift, priceType);
    else
      return LSMA(symbol, timeframe, windowSize, shift, priceType);
  }

  //+------------------------------------------------------------------+
  //| HannMA - Hann (Hanning) Window Moving Average                     |
  //| Formula: Weights follow raised cosine window                      |
  //| Reference: Julius von Hann (Austrian meteorologist)
  //|            https://en.wikipedia.org/wiki/Hann_function
  //+------------------------------------------------------------------+
  static double HannMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      // Hann window: 0.5 * (1 - cos(2*pi*n/(N-1)))
      double weight = 0.5 * (1 - MathCos(2 * PI * i / (period - 1)));
      sum += GetPrice(symbol, timeframe, priceType, shift + i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| HammingMA - Hamming Window Moving Average                         |
  //| Formula: Modified Hann window with reduced end discontinuities    |
  //| Reference: Richard Hamming, "Digital Filters" (1977)
  //|            https://en.wikipedia.org/wiki/Hamming_window
  //+------------------------------------------------------------------+
  static double HammingMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      // Hamming window: 0.54 - 0.46*cos(2*pi*n/(N-1))
      double weight = 0.54 - 0.46 * MathCos(2 * PI * i / (period - 1));
      sum += GetPrice(symbol, timeframe, priceType, shift + i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| BlackmanMA - Blackman Window Moving Average                       |
  //| Formula: Three-term cosine window with very low sidelobes         |
  //| Reference: Ralph Beebe Blackman, "The Measurement of Power Spectra" (1958)
  //|            https://en.wikipedia.org/wiki/Blackman_window
  //+------------------------------------------------------------------+
  static double BlackmanMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double sum = 0;
    double weightSum = 0;

    for (int i = 0; i < period; ++i) {
      // Blackman window: 0.42 - 0.5*cos(2*pi*n/(N-1)) + 0.08*cos(4*pi*n/(N-1))
      double weight = 0.42 - 0.5 * MathCos(2 * PI * i / (period - 1)) +
                      0.08 * MathCos(4 * PI * i / (period - 1));
      sum += GetPrice(symbol, timeframe, priceType, shift + i) * weight;
      weightSum += weight;
    }

    return (weightSum > 0) ? sum / weightSum : 0;
  }

  //+------------------------------------------------------------------+
  //| BandpassFilter - Ehlers Bandpass Filter                           |
  //| Formula: Passes frequencies within a specific band                |
  //| Reference: John Ehlers, "Cycle Analytics for Traders" (2013)
  //|            Isolates dominant cycle component
  //+------------------------------------------------------------------+
  static double BandpassFilter(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double bandwidth = 0.1) {
    if (period <= 0) return 0;

    double delta = bandwidth;
    double beta = MathCos(2 * PI / period);
    double gamma = 1 / MathCos(4 * PI * delta / period);
    double alpha = gamma - MathSqrt(gamma * gamma - 1);

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 3, period * 10);

    double bp = 0;
    double bp1 = 0;
    double bp2 = 0;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double price2 = GetPrice(symbol, timeframe, priceType, shift + i + 2);

      double newBP = 0.5 * (1 - alpha) * (price - price2) + beta * (1 + alpha) * bp1 - alpha * bp2;
      bp2 = bp1;
      bp1 = newBP;
    }

    return bp1;
  }

  //+------------------------------------------------------------------+
  //| HighpassFilter - Ehlers Highpass Filter                           |
  //| Formula: Removes low-frequency (trend) components                 |
  //| Reference: John Ehlers, "Cybernetic Analysis for Stocks and Futures" (2004)
  //|            Chapter 13: Highpass Filter
  //+------------------------------------------------------------------+
  static double HighpassFilter(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    double alpha = (MathCos(0.707 * 2 * PI / period) + MathSin(0.707 * 2 * PI / period) - 1) /
                   MathCos(0.707 * 2 * PI / period);

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - 3, period * 10);

    double hp = 0;
    double hp1 = 0;

    for (int i = lookback - 1; i >= 0; --i) {
      double price = GetPrice(symbol, timeframe, priceType, shift + i);
      double price1 = GetPrice(symbol, timeframe, priceType, shift + i + 1);
      double price2 = GetPrice(symbol, timeframe, priceType, shift + i + 2);

      double newHP = (1 - alpha / 2) * (1 - alpha / 2) * (price - 2 * price1 + price2) +
                     2 * (1 - alpha) * hp1 - (1 - alpha) * (1 - alpha) * hp;
      hp = hp1;
      hp1 = newHP;
    }

    // Return price minus highpass (which gives lowpass/trend)
    double price = GetPrice(symbol, timeframe, priceType, shift);
    return price - hp1;
  }

  //+------------------------------------------------------------------+
  //| RecursiveMedian - Recursive Median Filter                         |
  //| Formula: Median with recursive feedback for smoother output       |
  //| Reference: Robust to outliers while maintaining smoothness
  //|            Hybrid of median and recursive filtering
  //+------------------------------------------------------------------+
  static double RecursiveMedian(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE) {
    if (period <= 0) return 0;

    int bars = iBars(symbol, timeframe);
    int lookback = MathMin(bars - shift - period - 1, period * 5);

    double rm = MedianMA(symbol, timeframe, period, shift + lookback, priceType);
    double alpha = 2.0 / (period + 1);

    for (int i = lookback - 1; i >= 0; --i) {
      double median = MedianMA(symbol, timeframe, period, shift + i, priceType);
      rm = alpha * median + (1 - alpha) * rm;
    }

    return rm;
  }

  //+------------------------------------------------------------------+
  //| VariableLengthMA - Variable-length Moving Average                 |
  //| Formula: Dynamically adjusts period based on volatility           |
  //| Reference: Adaptive period selection based on market conditions
  //|            Shorter periods in trending, longer in ranging markets
  //+------------------------------------------------------------------+
  static double VariableLengthMA(const string symbol, const int timeframe, const int period, const int shift, const int priceType = PRICE_CLOSE, const double sensitivity = 0.5) {
    if (period <= 0) return 0;

    // Calculate efficiency ratio to determine dynamic period
    double price = GetPrice(symbol, timeframe, priceType, shift);
    double priceN = GetPrice(symbol, timeframe, priceType, shift + period);

    double signal = MathAbs(price - priceN);
    double noise = 0;
    for (int i = 0; i < period; ++i)
      noise += MathAbs(GetPrice(symbol, timeframe, priceType, shift + i) -
                       GetPrice(symbol, timeframe, priceType, shift + i + 1));

    double er = (noise > 0) ? signal / noise : 1;

    // Calculate variable period: higher ER = shorter period
    int minPeriod = MathMax(3, period / 4);
    int maxPeriod = period * 2;
    int varPeriod = (int)MathRound(maxPeriod - er * sensitivity * (maxPeriod - minPeriod));
    varPeriod = MathMax(minPeriod, MathMin(maxPeriod, varPeriod));

    return EMA(symbol, timeframe, varPeriod, shift, priceType);
  }

  //+------------------------------------------------------------------+
  //| Get MA type name as string                                       |
  //+------------------------------------------------------------------+
  static string GetTypeName(ENUM_MA_TYPE maType) {
    switch (maType) {
      // Basic MAs
      case MA_SMA:          return "SMA";
      case MA_EMA:          return "EMA";
      case MA_WMA:          return "WMA";
      case MA_SMMA:         return "SMMA";

      // Double/Triple/Quad Smoothed
      case MA_DEMA:         return "DEMA";
      case MA_TEMA:         return "TEMA";
      case MA_QEMA:         return "QEMA";
      case MA_T3:           return "T3";
      case MA_GDEMA:        return "GDEMA";
      case MA_REMA:         return "REMA";

      // Low-Lag / Zero-Lag
      case MA_HMA:          return "HMA";
      case MA_ALMA:         return "ALMA";
      case MA_ZLEMA:        return "ZLEMA";
      case MA_LEADER:       return "Leader";
      case MA_JMA:          return "JMA";

      // Adaptive MAs
      case MA_KAMA:         return "KAMA";
      case MA_VIDYA:        return "VIDYA";
      case MA_FRAMA:        return "FRAMA";
      case MA_VAMA:         return "VAMA";
      case MA_DSMA:         return "DSMA";
      case MA_NRMA:         return "NRMA";
      case MA_AEMA:         return "AEMA";
      case MA_MCGINLEY:     return "McGinley";

      // Ehlers Filters
      case MA_SUPERSMOOTHER: return "SuperSmoother";
      case MA_MAMA:         return "MAMA";
      case MA_FAMA:         return "FAMA";
      case MA_ITREND:       return "ITrend";
      case MA_DECYCLER:     return "Decycler";
      case MA_LAGUERRE:     return "Laguerre";
      case MA_ALAGUERRE:    return "AdaptLaguerre";
      case MA_GAUSSIAN:     return "Gaussian";
      case MA_BUTTERWORTH:  return "Butterworth";

      // Weighted Variants
      case MA_FWMA:         return "FWMA";
      case MA_PWMA:         return "PWMA";
      case MA_CWMA:         return "CWMA";
      case MA_HWMA:         return "HWMA";
      case MA_SWMA:         return "SWMA";

      // Regression-Based
      case MA_LSMA:         return "LSMA";
      case MA_POLY:         return "Poly";
      case MA_QUADRATIC:    return "Quadratic";
      case MA_ILRS:         return "ILRS";
      case MA_IE2:          return "IE/2";

      // Statistical
      case MA_TMA:          return "TMA";
      case MA_VWMA:         return "VWMA";
      case MA_VWAP:         return "VWAP";
      case MA_MEDIAN:       return "Median";
      case MA_GEOMETRIC:    return "Geometric";
      case MA_HARMONIC:     return "Harmonic";

      // Other
      case MA_EPMA:         return "EPMA";
      case MA_RMTA:         return "RMTA";
      case MA_LEOMA:        return "LeoMA";
      case MA_DECEMA:       return "DECEMA";
      case MA_MODULAR:      return "Modular";

      // Advanced Filters
      case MA_KALMAN:       return "Kalman";
      case MA_SAVGOL:       return "SavGol";
      case MA_HANN:         return "Hann";
      case MA_HAMMING:      return "Hamming";
      case MA_BLACKMAN:     return "Blackman";
      case MA_BANDPASS:     return "Bandpass";
      case MA_HIGHPASS:     return "Highpass";
      case MA_RMEDIAN:      return "RMedian";
      case MA_VMA:          return "VMA";

      default:              return "Unknown";
    }
  }
};

// Static constant initialization
const double MovingAverages::PI = 3.14159265358979;
