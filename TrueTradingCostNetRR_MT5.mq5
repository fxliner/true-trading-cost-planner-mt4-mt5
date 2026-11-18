//+------------------------------------------------------------------+
//| True Trading Cost & Net Risk Reward for MT5                      |
//| Source code for educational use (2026)                              |
//| Educational planning indicator. No order placement.             |
//+------------------------------------------------------------------+
#property copyright "FOREXREVIEW.TOP (2026)"
#property version   "1.20"
#property description "Interactive entry / stop / target cost planner."
#property description "Shows live spread, net R:R, break-even and risk-based lots."
#property description "No trade signals or automated orders."
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

enum ENUM_TTC_SIZING { TTC_RISK_PERCENT=0, TTC_FIXED_LOT=1 };
input ENUM_TTC_SIZING InpSizing             = TTC_RISK_PERCENT; // Position sizing mode
input double InpRiskPercent                = 1.00; // Risk % of account equity
input double InpFixedLots                  = 0.10; // Fixed volume in lots
input double InpCommissionRoundTurnPerLot  = 0.00; // Commission per lot round-trip, account currency
input bool   InpCommissionVerified         = false; // I have verified commission (including zero)
input double InpExtraFeesRoundTurnPerLot   = 0.00; // Additional known fees per lot, account currency
input double InpSlippageRoundTurnPoints    = 0.00; // Assumed total round-trip slippage, points
input double InpInitialStopATRMultiplier   = 1.20; // Initial stop distance, ATR(14) multiple
input double InpInitialTargetRR            = 2.00; // Initial target / stop distance
input int    InpFallbackStopPoints         = 200;  // Stop distance if ATR unavailable
input int    InpPanelX                     = 16;   // Dashboard X (pixels)
input int    InpPanelY                     = 26;   // Dashboard Y (pixels)
input bool   InpShowBreakEvenLine          = true; // Draw projected break-even line
input double InpWarnCostTargetPercent      = 15.0; // Warn if fees exceed % target (0=off)
input int    InpUpdateSeconds              = 3;    // Refresh seconds (1..60)
enum ENUM_TTC_SWAP_SOURCE { TTC_SWAP_OFF=0, TTC_SWAP_AUTO=1, TTC_SWAP_MANUAL=2 };
input ENUM_TTC_SWAP_SOURCE InpSwapSource  = TTC_SWAP_AUTO; // Off, broker estimate or manual
input int    InpRolloverDays              = 3;     // Future server-calendar days (0..30)
input double InpManualSwapPerLotNight     = -5.0;  // Account currency per 1 lot per standard night
input int    InpTripleSwapWeekday         = 3;     // For manual/MT4 (0 Sunday, 3 Wednesday)
input int    InpSwapStartWeekdayOverride   = -1;    // -1=auto; 0=Sun..6=Sat (manual simulation)
input bool   InpSwapCalendarVerified     = false; // Verify rollover calendar with broker
input bool   InpIncludeSwapInNetRR        = false; // Only includes swap if verified
input bool   InpUseManualSymbolSpecs      = false; // Explicit offline/manual simulation mode
input double InpManualTickSizePrice       = 0.00001; // Price increment (not points)
input double InpManualTickValueProfit     = 1.0;   // Per tick/lot, account currency
input double InpManualTickValueLoss       = 1.0;   // Per tick/lot, account currency
input double InpManualMinLot              = 0.01;  // Simulated contract min lot
input double InpManualMaxLot              = 100.0; // Simulated contract max lot
input double InpManualLotStep             = 0.01;  // Simulated contract lot step
input string InpManualAccountCurrency    = "USD"; // Label if broker currency unavailable
input bool   InpCollectSpreadStats        = true;  // Samples since attach, reset by server date
input bool   InpShowInsightsPanel         = true;  // Show swap and spread sidebar


string g_prefix="";
string g_currency="";
bool   g_buy=true;
bool   g_initialized=false;
int    g_digits=5;
double g_point=0.00001;
double g_tick_size=0.00001;
int g_statDate=0;
datetime g_lastSpreadTick=0;
datetime g_observedTickTime=0;
datetime g_lastNewTickWall=0;
bool g_seenFreshTick=false;
double g_spreadSum[4];
double g_spreadMax[4];
int g_spreadN[4];

color  CLR_BG=C'16,24,38';
color  CLR_ROW=C'25,36,54';
color  CLR_WHITE=C'235,241,249';
color  CLR_MUTED=C'160,176,197';
color  CLR_GREEN=C'64,219,159';
color  CLR_RED=C'251,113,133';
color  CLR_YELLOW=C'251,191,70';
color  CLR_BLUE=C'84,166,245';

// Protect against nonsensical inputs and avoid producing an unsafe lot size.
double ClampPositive(const double value) { return MathMax(0.0,value); }
string PriceText(const double price) { return DoubleToString(price,g_digits); }
string Money(const double value) { return g_currency+" "+DoubleToString(value,2); }
string VolumeText(const double value)
  {
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   int decimals=(step<0.01 ? 3 : 2);
   if(step<0.001) decimals=5;
   return DoubleToString(value,decimals);
  }
double PriceRound(const double price)
  {
   return NormalizeDouble(MathRound(price/g_tick_size)*g_tick_size,g_digits);
  }
string Name(const string suffix) { return g_prefix+suffix; }

void PanelRectangle(const string id,const int x,const int y,const int w,const int h,const color bg)
  {
   string n=Name(id);
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,InpPanelX+x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,InpPanelY+y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_COLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,n,OBJPROP_BACK,false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
  }
void PanelText(const string id,const string caption,const int x,const int y,const int size,const color col)
  {
   string n=Name(id);
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,InpPanelX+x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,InpPanelY+y);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,n,OBJPROP_COLOR,col);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
   ObjectSetString(0,n,OBJPROP_FONT,"Segoe UI");
   ObjectSetString(0,n,OBJPROP_TEXT,caption);
  }
void PanelButton(const string id,const string caption,const int x,const int y,const int w,const color bg)
  {
   string n=Name(id);
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,InpPanelX+x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,InpPanelY+y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,24);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_COLOR,CLR_WHITE);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,10);
   ObjectSetString(0,n,OBJPROP_FONT,"Segoe UI");
   ObjectSetString(0,n,OBJPROP_TEXT,caption);
  }
void SetPriceLine(const string id,const double price,const color col,const ENUM_LINE_STYLE style,const bool selectable)
  {
   string n=Name(id);
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_HLINE,0,0,price);
   ObjectSetDouble(0,n,OBJPROP_PRICE,price);
   ObjectSetInteger(0,n,OBJPROP_COLOR,col);
   ObjectSetInteger(0,n,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,n,OBJPROP_STYLE,style);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,selectable);
   ObjectSetInteger(0,n,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,n,OBJPROP_BACK,true);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,false);
   ObjectSetString(0,n,OBJPROP_TOOLTIP,"TTC "+id+": drag line to adjust planned execution price");
  }
double LinePrice(const string id)
  {
   if(ObjectFind(0,Name(id))<0) return 0;
   return ObjectGetDouble(0,Name(id),OBJPROP_PRICE,0);
  }
bool GetLiveTick(MqlTick &q)
  {
   if(!SymbolInfoTick(_Symbol,q)) return false;
   return(q.bid>0.0 && q.ask>=q.bid && q.ask>0.0);
  }
double InitialStopDistance()
  {
   double distance=ClampPositive(InpFallbackStopPoints)*g_point;
   int handle=iATR(_Symbol,_Period,14);
   if(handle!=INVALID_HANDLE)
     {
      double atr[];
      if(CopyBuffer(handle,0,1,1,atr)==1 && atr[0]>0.0)
         distance=atr[0]*MathMax(0.2,InpInitialStopATRMultiplier);
      IndicatorRelease(handle);
     }
   return MathMax(distance,5*g_tick_size);
  }
void ResetPlan()
  {
   MqlTick q;
   if(!GetLiveTick(q)) { g_initialized=false; return; }
   double entry=PriceRound(g_buy?q.ask:q.bid);
   double delta=InitialStopDistance();
   double sl=PriceRound(entry+(g_buy?-delta:delta));
   double tp=PriceRound(entry+(g_buy?delta:-delta)*MathMax(0.25,InpInitialTargetRR));
   SetPriceLine("ENTRY",entry,CLR_BLUE,STYLE_SOLID,true);
   SetPriceLine("STOP",sl,CLR_RED,STYLE_SOLID,true);
   SetPriceLine("TARGET",tp,CLR_GREEN,STYLE_SOLID,true);
   g_initialized=true;
  }
// Spread is already in executable entry and exit prices: do not add it again.
// NOTE: Tick values are broker-provided approximations in deposit currency.
// Profit/loss tick values can differ because of currency conversion spreads.
bool TickValues(double &for_profit,double &for_loss)
  {
   g_tick_size=TTCTickSizePrice();
   if(g_tick_size<=0) return false;
   if(InpUseManualSymbolSpecs)
     {
      for_profit=InpManualTickValueProfit;
      for_loss=InpManualTickValueLoss;
     }
   else
     {
      for_profit=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_PROFIT);
      for_loss=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
     }
   return(for_profit>0.0 && for_loss>0.0 && MathIsValidNumber(for_profit) && MathIsValidNumber(for_loss));
  }
double RoundTripCostPerLot(const double tick_loss)
  {
   double slip=ClampPositive(InpSlippageRoundTurnPoints)*g_point/g_tick_size*tick_loss;
   return ClampPositive(InpCommissionRoundTurnPerLot)+ClampPositive(InpExtraFeesRoundTurnPerLot)+slip;
  }
double NormalizeVolumeFloor(const double candidate)
  {
   double minlot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxlot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(InpUseManualSymbolSpecs)
     {
      minlot=InpManualMinLot;
      maxlot=InpManualMaxLot;
      step=InpManualLotStep;
     }
   if(step<=0.0 || minlot<=0.0 || maxlot<minlot || candidate<minlot) return 0.0;
   double cap=MathMin(candidate,maxlot);
   double volume=minlot+MathFloor((cap-minlot)/step+1e-9)*step;
   if(volume+1e-9<minlot) return 0.0;
   return NormalizeDouble(volume,8);
  }
void SampleSpreadByBrokerHour(const double spreadPts,const datetime quoteTime,const bool stale)
  {
   if(!InpCollectSpreadStats || stale || quoteTime<=0 || spreadPts<0) return;
   MqlDateTime dt; TimeToStruct(quoteTime,dt);
   int key=dt.year*10000+dt.mon*100+dt.day;
   if(g_statDate!=key)
     {
      g_statDate=key; g_lastSpreadTick=0;
      ArrayInitialize(g_spreadSum,0.0);
      ArrayInitialize(g_spreadMax,0.0);
      ArrayInitialize(g_spreadN,0);
     }
   if(quoteTime==g_lastSpreadTick) return;
   g_lastSpreadTick=quoteTime;
   int slot=(int)MathMin(3,dt.hour/6);
   g_spreadSum[slot]+=spreadPts;
   g_spreadMax[slot]=MathMax(g_spreadMax[slot],spreadPts);
   g_spreadN[slot]++;
  }
double TTCFallbackDayWeight(const int d,const int triple)
  {
   if(d==triple) return 3.0;
   if(d==0 || d==6) return 0.0;
   return 1.0;
  }
void DrawInsights(const bool known,const double swapPerLot,const double lots,
                  const string source,const bool included,const bool stale)
  {
   if(!InpShowInsightsPanel) return;
   string status=known?source:"Unsupported: use MANUAL";
   PanelText("SWAPMODE","Swap source: "+status,397,32,9,known?CLR_MUTED:CLR_YELLOW);
   PanelText("SWAPNIGHTS","Forward calendar days: "+IntegerToString(InpRolloverDays),397,54,9,CLR_MUTED);
   PanelText("SWAPLOT","Swap per 1 lot: "+(known?Money(swapPerLot):"n/a"),397,76,9,CLR_WHITE);
   PanelText("SWAPTOTAL","At planned size: "+(known&&lots>0?Money(swapPerLot*lots):"n/a"),397,98,9,
             known&&swapPerLot<0?CLR_YELLOW:CLR_GREEN);
   PanelText("SWAPNET",included?"Included in net P/L":"Not included in net P/L",397,120,8,
             included?CLR_GREEN:CLR_MUTED);
   string hours[4]={"00-05","06-11","12-17","18-23"};
   for(int i=0;i<4;i++)
     {
      string value=(g_spreadN[i]>0 ?
         "avg "+DoubleToString(g_spreadSum[i]/g_spreadN[i],1)+
         " peak "+DoubleToString(g_spreadMax[i],1)+
         " n="+IntegerToString(g_spreadN[i]):"no samples");
      PanelText("BLOCK"+IntegerToString(i),hours[i]+"  "+value,396,170+i*19,8,CLR_MUTED);
     }
   PanelText("SPNOTE",stale?"Quote stale: sampling paused":"Distinct tick seconds only; daily reset",
             396,253,8,stale?CLR_YELLOW:CLR_MUTED);
  }

double TTCTickSizePrice()
  {
   if(InpUseManualSymbolSpecs) return InpManualTickSizePrice;
   return SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
  }
double TTCBrokerDayWeight(const int day)
  {
   double weight[7];
   weight[0]=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_SUNDAY);
   weight[1]=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_MONDAY);
   weight[2]=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_TUESDAY);
   weight[3]=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_WEDNESDAY);
   weight[4]=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_THURSDAY);
   weight[5]=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_FRIDAY);
   weight[6]=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_SATURDAY);
   double sum=0;for(int i=0;i<7;i++) sum+=MathAbs(weight[i]);
   if(sum>0.01) return weight[day];
   int triple=(int)SymbolInfoInteger(_Symbol,SYMBOL_SWAP_ROLLOVER3DAYS);
   if(triple<0 || triple>6) triple=InpTripleSwapWeekday;
   return TTCFallbackDayWeight(day,triple);
  }
bool TTCProjectedSwap(double &total,string &method,const double profitTV,const double lossTV)
  {
   total=0.0;method="Off";
   if(InpSwapSource==TTC_SWAP_OFF || InpRolloverDays<=0) return true;
   double daily=0.0;
   bool manual=(InpSwapSource==TTC_SWAP_MANUAL);
   if(manual){daily=InpManualSwapPerLotNight;method="Manual";}
   else
     {
      int mode=(int)SymbolInfoInteger(_Symbol,SYMBOL_SWAP_MODE);
      double raw=SymbolInfoDouble(_Symbol,g_buy?SYMBOL_SWAP_LONG:SYMBOL_SWAP_SHORT);
      if(mode==SYMBOL_SWAP_MODE_DISABLED){daily=0.0;method="Broker disabled";}
      else if(mode==SYMBOL_SWAP_MODE_POINTS)
        {
         if(g_tick_size<=0 || profitTV<=0 || lossTV<=0){method="Tick value missing";return false;}
         daily=raw*g_point/g_tick_size*(raw>=0?profitTV:lossTV);
         method="Broker points";
        }
      else if(mode==SYMBOL_SWAP_MODE_CURRENCY_DEPOSIT){daily=raw;method="Account currency";}
      else if(mode==SYMBOL_SWAP_MODE_CURRENCY_MARGIN &&
              SymbolInfoString(_Symbol,SYMBOL_CURRENCY_MARGIN)==AccountInfoString(ACCOUNT_CURRENCY))
        {daily=raw;method="Margin=deposit";}
      else if(mode==SYMBOL_SWAP_MODE_CURRENCY_SYMBOL &&
              SymbolInfoString(_Symbol,SYMBOL_CURRENCY_BASE)==AccountInfoString(ACCOUNT_CURRENCY))
        {daily=raw;method="Base=deposit";}
      else{method="Unsupported broker model";return false;}
     }
   datetime now=(g_seenFreshTick?TimeTradeServer():TimeLocal());
   MqlDateTime dt;TimeToStruct(now>0?now:TimeLocal(),dt);
   if(InpSwapStartWeekdayOverride>=0) dt.day_of_week=InpSwapStartWeekdayOverride;
   for(int i=0;i<InpRolloverDays;i++)
     {
      int wd=(dt.day_of_week+i)%7;
      double multiplier=(manual?TTCFallbackDayWeight(wd,InpTripleSwapWeekday):TTCBrokerDayWeight(wd));
      total+=daily*multiplier;
     }
   return true;
  }

void DrawStatic()
  {
   PanelRectangle("BG",0,0,374,467,CLR_BG);
   PanelRectangle("H",1,1,372,48,CLR_ROW);
   PanelText("TITLE","TRUE TRADING COST",14,7,12,CLR_WHITE);
   PanelText("SUB","Risk & Reward | MT5",14,28,9,CLR_MUTED);
   PanelButton("BUY","BUY",180,12,53,g_buy?C'29,139,95':CLR_ROW);
   PanelButton("SELL","SELL",238,12,53,g_buy?CLR_ROW:C'169,58,84');
   PanelButton("RESET","RESET",296,12,66,C'50,69,91');
   PanelRectangle("SEPARATOR",11,119,350,1,C'55,72,91');
   PanelRectangle("CALC",10,203,354,182,CLR_ROW);
   PanelText("BRAND","TRUE TRADING COST",13,443,10,CLR_BLUE);
   PanelText("BRAND2","Planning only - no order placement",147,445,8,CLR_MUTED);
   if(InpShowInsightsPanel)
     {
      PanelRectangle("INSIGHTS",384,0,299,278,CLR_BG);
      PanelRectangle("INSHEADER",385,1,297,25,CLR_ROW);
      PanelText("INSTITLE","OVERNIGHT & SPREAD INSIGHTS",397,5,10,CLR_WHITE);
      PanelRectangle("INSRULE",396,141,266,1,C'55,72,91');
      PanelText("SPTITLE","SPREAD BY BROKER SERVER HOUR (pts)",396,148,8,CLR_BLUE);
     }
  }
void UpdateReadout()
  {
   if(!g_initialized)
     {
      MqlTick q;
      if(GetLiveTick(q)) ResetPlan();
      if(!g_initialized)
        {
         PanelText("WAIT","Waiting for a valid market quote...",13,70,10,CLR_YELLOW);
         return;
        }
     }
   if(ObjectFind(0,Name("WAIT"))>=0) ObjectDelete(0,Name("WAIT"));
   MqlTick quote;
   bool quote_ok=GetLiveTick(quote);
   bool connected=(bool)TerminalInfoInteger(TERMINAL_CONNECTED);
   // A cached quote at startup is NOT treated as fresh. Require a new tick timestamp
   // observed after the indicator starts, then monitor its age on the local monotonic clock.
   if(quote_ok && quote.time>0)
     {
      if(g_observedTickTime==0) g_observedTickTime=quote.time;
      else if(quote.time!=g_observedTickTime)
        {
         g_observedTickTime=quote.time;
         g_lastNewTickWall=TimeLocal();
         g_seenFreshTick=true;
        }
     }
   bool quote_stale=(!connected || !g_seenFreshTick || g_lastNewTickWall<=0 ||
                     (TimeLocal()-g_lastNewTickWall)>300);
   double spread_points=(quote_ok?(quote.ask-quote.bid)/g_point:0.0);
   if(quote_ok) SampleSpreadByBrokerHour(spread_points,quote.time,quote_stale);
   double entry=LinePrice("ENTRY"),sl=LinePrice("STOP"),tp=LinePrice("TARGET");
   bool valid=(entry>0 && sl>0 && tp>0 &&
              (g_buy?(sl<entry && tp>entry):(sl>entry && tp<entry)));
   double profit_tv=0.0,loss_tv=0.0;
   bool tick_valid=TickValues(profit_tv,loss_tv);
   double swapPerLot=0.0;
   string swapMethod="Off";
   bool swapKnown=TTCProjectedSwap(swapPerLot,swapMethod,profit_tv,loss_tv);
   bool includeSwap=(InpIncludeSwapInNetRR && InpSwapCalendarVerified && swapKnown &&
                     InpSwapSource!=TTC_SWAP_OFF && InpRolloverDays>0);
   double stop_distance=MathAbs(entry-sl);
   double tp_distance=MathAbs(tp-entry);
   double per_lot_loss=0.0,per_lot_gain=0.0,per_lot_cost=0.0;
   double budget=ClampPositive(AccountInfoDouble(ACCOUNT_EQUITY))*ClampPositive(InpRiskPercent)/100.0;
   double lots=0.0;
   if(valid && tick_valid)
     {
      per_lot_loss=stop_distance/g_tick_size*loss_tv;
      per_lot_gain=tp_distance/g_tick_size*profit_tv;
      per_lot_cost=RoundTripCostPerLot(loss_tv);
      double sizingRisk=per_lot_loss+per_lot_cost+(includeSwap?MathMax(0.0,-swapPerLot):0.0);
      if(InpSizing==TTC_RISK_PERCENT && sizingRisk>0.0)
         lots=NormalizeVolumeFloor(budget/sizingRisk);
      else if(InpSizing==TTC_FIXED_LOT)
         lots=NormalizeVolumeFloor(ClampPositive(InpFixedLots));
     }
   double gross_loss=per_lot_loss*lots, gross_gain=per_lot_gain*lots;
   double costs=per_lot_cost*lots;
   double swapAmount=swapPerLot*lots;
   // Conservative risk: negative swap increases loss, positive swap does not reduce stop risk.
   double net_loss=gross_loss+costs+(includeSwap?MathMax(0.0,-swapAmount):0.0);
   double net_gain=gross_gain-costs+(includeSwap?swapAmount:0.0);
   double gross_rr=(per_lot_loss>0.0 ? per_lot_gain/per_lot_loss : 0.0);
   double net_rr=(net_loss>0 ? net_gain/net_loss : 0.0);
   double spread_cost=(quote_ok && tick_valid?spread_points*g_point/g_tick_size*loss_tv*lots:0.0);
   string spread_caption=(quote_ok?DoubleToString(spread_points,1)+" pts":"No live quote");
   if(quote_ok && (g_digits==3 || g_digits==5))
      spread_caption+=" ("+DoubleToString(spread_points/10.0,1)+" pips)";
   PanelText("SYMBOL",_Symbol+"  |  "+(g_buy?"BUY @ Ask":"SELL @ Bid"),13,57,11,CLR_WHITE);
   if(quote_stale) spread_caption+=" (cached)";
   PanelText("SPREAD","LATEST SPREAD   "+spread_caption,13,80,9,quote_stale?CLR_YELLOW:CLR_MUTED);
   PanelText("SPREADVAL","Spread equivalent at size: "+(lots>0?Money(spread_cost):"n/a"),13,101,9,CLR_MUTED);
   PanelText("ENTRYTXT","ENTRY    "+PriceText(entry),13,129,10,CLR_BLUE);
   PanelText("SLTXT","STOP      "+PriceText(sl),13,154,10,CLR_RED);
   PanelText("TPTXT","TARGET  "+PriceText(tp),13,179,10,CLR_GREEN);
   PanelText("SIZETXT","POSITION   "+(lots>0?VolumeText(lots)+" lots":"not available"),20,211,10,CLR_WHITE);
   PanelText("BUDGET","Risk budget: "+Money(budget)+(InpSizing==TTC_FIXED_LOT?" (fixed mode)":" (equity %)"),20,234,9,(InpSizing==TTC_FIXED_LOT&&budget>0&&net_loss>budget)?CLR_YELLOW:CLR_MUTED);
   PanelText("COST","Fees + slippage scenario: "+(lots>0?Money(costs):"n/a"),20,254,9,CLR_MUTED);
   PanelText("GROSS","Gross risk / reward:   "+Money(gross_loss)+" / "+Money(gross_gain),20,278,9,CLR_WHITE);
   PanelText("NET","Net risk / reward:       "+Money(net_loss)+" / "+Money(net_gain),20,300,10,valid&&lots>0&&net_gain>0?CLR_GREEN:CLR_YELLOW);
   PanelText("RR","R:R gross  1:"+DoubleToString(gross_rr,2)+"  |  net  1:"+DoubleToString(net_rr,2),20,325,10,CLR_WHITE);
   double beFees=per_lot_cost-(includeSwap?swapPerLot:0.0);
   double be_delta=(tick_valid && profit_tv>0 ? beFees/profit_tv*g_tick_size : 0.0);
   double be=PriceRound(entry+(g_buy?be_delta:-be_delta));
   if(InpShowBreakEvenLine && tick_valid && valid)
      SetPriceLine("BE_LINE",be,CLR_YELLOW,STYLE_DOT,false);
   else if(ObjectFind(0,Name("BE_LINE"))>=0) ObjectDelete(0,Name("BE_LINE"));
   PanelText("BREAKEVEN","Break-even (est.): "+(valid&&tick_valid?PriceText(be):"n/a"),20,346,9,CLR_YELLOW);
   double modeledOutlay=costs+(includeSwap?MathMax(0.0,-swapAmount):0.0);
   double cost_ratio=(gross_gain>0?100.0*modeledOutlay/gross_gain:0.0);
   PanelText("COSTRATIO","Costs / gross target: "+(lots>0&&gross_gain>0?DoubleToString(cost_ratio,1)+"%":"n/a"),20,367,9,(InpWarnCostTargetPercent>0&&cost_ratio>InpWarnCostTargetPercent)?CLR_YELLOW:CLR_MUTED);
   string state="PLAN READY";
   color state_color=CLR_GREEN;
   if(!quote_ok) { state="MARKET QUOTE UNAVAILABLE"; state_color=CLR_YELLOW; }
   else if(quote_stale) { state="MARKET OFFLINE / QUOTE MAY BE STALE"; state_color=CLR_YELLOW; }
   else if(!tick_valid) { state="TICK VALUE UNAVAILABLE - CHECK BROKER"; state_color=CLR_RED; }
   else if(!valid) { state="INVALID ENTRY / STOP / TARGET LEVELS"; state_color=CLR_RED; }
   else if(lots<=0) { state="LOT BELOW MINIMUM OR EQUITY UNAVAILABLE"; state_color=CLR_YELLOW; }
   else if(!InpCommissionVerified) { state="COMMISSION NOT VERIFIED - NET ESTIMATE"; state_color=CLR_YELLOW; }
   else if(net_gain<=0) { state="COSTS EXCEED GROSS TARGET"; state_color=CLR_RED; }
   else if(InpSizing==TTC_FIXED_LOT && budget>0 && net_loss>budget) { state="FIXED LOT EXCEEDS RISK BUDGET"; state_color=CLR_YELLOW; }
   else if(InpWarnCostTargetPercent>0&&cost_ratio>InpWarnCostTargetPercent) { state="HIGH COST / TARGET - REVIEW PLAN"; state_color=CLR_YELLOW; }
   if(valid && tick_valid && lots>0 && InpUseManualSymbolSpecs)
     { state="MANUAL SYMBOL SPECS - SIMULATION"; state_color=CLR_YELLOW; }
   else if(valid && tick_valid && lots>0 && InpIncludeSwapInNetRR && !includeSwap)
     { state="SWAP UNVERIFIED - EXCLUDED FROM NET"; state_color=CLR_YELLOW; }
   PanelText("DRAGHINT","Drag the blue, red and green chart lines to plan.",13,393,8,CLR_MUTED);
   PanelText("STATE",state,13,405,9,state_color);
   PanelText("NOTE","Spread is already in Bid/Ask execution prices.",13,424,8,CLR_MUTED);
   DrawInsights(swapKnown,swapPerLot,lots,swapMethod,includeSwap,quote_stale);
   ChartRedraw(0);
  }
int OnInit()
  {
   g_prefix="FRTC_"+IntegerToString((int)GetTickCount())+"_";
   g_currency=AccountInfoString(ACCOUNT_CURRENCY);
   if(g_currency=="" && InpUseManualSymbolSpecs) g_currency=InpManualAccountCurrency+"*";
   g_digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   g_point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   g_tick_size=TTCTickSizePrice();
   if(g_point<=0 || g_tick_size<=0) return INIT_FAILED;
   if(InpRolloverDays<0 || InpRolloverDays>30 || InpTripleSwapWeekday<0 || InpTripleSwapWeekday>6 ||
      InpSwapStartWeekdayOverride< -1 || InpSwapStartWeekdayOverride>6 ||
      !MathIsValidNumber(InpManualSwapPerLotNight) ||
      (InpUseManualSymbolSpecs && (InpManualTickSizePrice<=0 || InpManualTickValueProfit<=0 ||
       InpManualTickValueLoss<=0 || InpManualMinLot<=0 || InpManualMaxLot<InpManualMinLot ||
       InpManualLotStep<=0)))
     {
      Print("True Trading Cost: invalid swap horizon or manual symbol specifications.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpRiskPercent<0 || InpFixedLots<0 || InpCommissionRoundTurnPerLot<0 ||
      InpExtraFeesRoundTurnPerLot<0 || InpSlippageRoundTurnPoints<0 || InpWarnCostTargetPercent<0)
     {
      Print("True Trading Cost: negative risk/lot/cost parameters are not allowed.");
      return INIT_PARAMETERS_INCORRECT;
     }
   IndicatorSetString(INDICATOR_SHORTNAME,"True Trading Cost & Net R:R");
   DrawStatic();
   ResetPlan();
   UpdateReadout();
   EventSetTimer((int)MathMax(1,MathMin(60,InpUpdateSeconds)));
   return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0,g_prefix);
   ChartRedraw(0);
  }
void OnTimer() { UpdateReadout(); }
// Indicators must have OnCalculate even if they draw only chart objects.
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],const long &volume[],
                const int &spread[])
  {
   if(prev_calculated==0) UpdateReadout();
   return rates_total;
  }
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam==Name("BUY")) { g_buy=true; ResetPlan(); DrawStatic(); UpdateReadout(); }
      if(sparam==Name("SELL")) { g_buy=false; ResetPlan(); DrawStatic(); UpdateReadout(); }
      if(sparam==Name("RESET")) { ResetPlan(); UpdateReadout(); }
      if(StringFind(sparam,g_prefix)==0) ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
     }
   if(id==CHARTEVENT_OBJECT_DRAG &&
      (sparam==Name("ENTRY") || sparam==Name("STOP") || sparam==Name("TARGET")))
     {
      ObjectSetDouble(0,sparam,OBJPROP_PRICE,PriceRound(ObjectGetDouble(0,sparam,OBJPROP_PRICE,0)));
      UpdateReadout();
     }
  }
//+------------------------------------------------------------------+
