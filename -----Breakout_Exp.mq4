//+------------------------------------------------------------------+
//|                                                  Breakout_Exp.mq4|
//|                                        Copyright (c) Yuya Yokota |
//+------------------------------------------------------------------+
#include <MQLMySQL.mqh>

//マジックナンバー
#define MAGIC  20070831

//パラメーター
extern int Fast_Period = 20;
extern int Slow_Period = 40;
extern double Lots = 0.1;
extern int Slippage = 3;

//+------------------------------------------------------------------+
//| オープンポジションの計算                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders()
{
   //オープンポジション数（+:買い -:売り）
   int pos=0;

   for(int i=0; i<OrdersTotal(); i++)//OrdersTotalは待機注文と保有ポジションの合計数を返す
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) break;
      //▲OrderSelectの処理、１つ目の引数（整数）で保有中のポジションを取得できるようになる。
      //▲２個目の引数は、インデックス番号か、チケット番号かの指定、チケット番号は複雑になる。
      //▲３個目の引数は、現在の注文か、過去の注文か選択
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGIC)
      {//OrderSymbolは現在選択中（OrderSelectとセットで使うやつ）の注文の通貨ペア名を返す
         //OrderMagicNumberは選択中の識別番号を返す
         if(OrderType() == OP_BUY)  pos++;
         if(OrderType() == OP_SELL) pos--;
      }
   }
   return(pos);//買いポジがあれば１を返す。売りなら-1を返す
}
//補足
//OrderTypeの種類
//0(OP_BUY)買いポジション
//1(OP_SELL)売りポジション
//2(OP_BUYLIMIT)指値買い注文
//3(OP_BUYSTOP)逆指値買い注文
//4(OP_SELLLIMIT)指値売り注文
//5(OP_SELLSTOP)逆指値売り注文


//+------------------------------------------------------------------+
//| ポジションを決済する                                             |
//+------------------------------------------------------------------+
void ClosePositions()
{
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) break;
      if(OrderMagicNumber() != MAGIC || OrderSymbol() != Symbol()) continue;
      //オーダータイプのチェック 
      if(OrderType() == OP_BUY)
      {
         OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
         break;
      }
      if(OrderType() == OP_SELL)
      {
         OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,White);
         break;
      }
   }
}
//OrderCloseの詳細
//１つめの引数、OrderTicketは決済する注文のチケット番号
//２個目はロット数、３つ目は決済価格、４つ目は許容スリッページ
//５つ目の色は、チャートで表示されるけさいオブジェクトのカラー


//ちなみに、オーダーチケットの番号とマジックナンバー（識別番号）はどう違うのか？
//これはかなり大切な概念！
//オーダーチケットはオーダーを送信したときに自動的に付与されるPK的なやつ
//マジックナンバーはEAを識別する番号。いろんなEAを同時に動かすときに混ざらないようにする目的。

//ってか、orderSelectで選択中のチケットの時に処理をするっていう考え方に慣れないといけない。

//+------------------------------------------------------------------+
//| スタート関数                                                     |
//+------------------------------------------------------------------+
int start()
{


   //バーの始値でトレード可能かチェック
   if(Volume[0] > 1 || IsTradeAllowed() == false) return(0);
   //volume[0]は最新のローソク足のティックの更新回数
   //相場が動いているかの確認。

   //指標の計算
   double SlowHH = Close[iHighest(NULL,0,MODE_CLOSE,Slow_Period,2)];
   double SlowLL = Close[iLowest(NULL,0,MODE_CLOSE,Slow_Period,2)];
   double FastHH = Close[iHighest(NULL,0,MODE_CLOSE,Fast_Period,2)];
   double FastLL = Close[iLowest(NULL,0,MODE_CLOSE,Fast_Period,2)];
   
   
   
   //移動平均線filtering
   double Ma1H = iMA(NULL,60,20,0,MODE_SMMA,PRICE_CLOSE,1);
   double Ma15M = iMA(NULL,15,20,0,MODE_SMMA,PRICE_CLOSE,1);
   double Ma5M = iMA(NULL,5,20,0,MODE_SMMA,PRICE_CLOSE,1);
   double Ma1M = iMA(NULL,1,20,0,MODE_SMMA,PRICE_CLOSE,1);
   int filter = 0;
   //filtering logic start
      if(Close[1] >= Ma1H && Close[1] >= Ma15M && Close[1] >= Ma5M && Close[1] >= Ma1M ){filter = 1;}
   if(Close[1] >= Ma1H && Close[1] >= Ma15M && Close[1] >= Ma5M && Close[1] < Ma1M ){filter = 2;}
   if(Close[1] >= Ma1H && Close[1] >= Ma15M && Close[1] < Ma5M && Close[1] >= Ma1M ){filter = 3;}
   if(Close[1] >= Ma1H && Close[1] >= Ma15M && Close[1] < Ma5M && Close[1] < Ma1M ){filter = 4;}
   if(Close[1] >= Ma1H && Close[1] < Ma15M && Close[1] >= Ma5M && Close[1] >= Ma1M ){filter = 5;}
   if(Close[1] >= Ma1H && Close[1] < Ma15M && Close[1] >= Ma5M && Close[1] < Ma1M ){filter = 6;}
   if(Close[1] >= Ma1H && Close[1] < Ma15M && Close[1] < Ma5M && Close[1] >= Ma1M ){filter = 7;}
   if(Close[1] >= Ma1H && Close[1] < Ma15M && Close[1] < Ma5M && Close[1] < Ma1M ){filter = 8;}
   
   if(Close[1] < Ma1H && Close[1] >= Ma15M && Close[1] >= Ma5M && Close[1] >= Ma1M ){filter = 9;}
   if(Close[1] < Ma1H && Close[1] >= Ma15M && Close[1] >= Ma5M && Close[1] < Ma1M ){filter = 10;}
   if(Close[1] < Ma1H && Close[1] >= Ma15M && Close[1] < Ma5M && Close[1] >= Ma1M ){filter = 11;}
   if(Close[1] < Ma1H && Close[1] >= Ma15M && Close[1] < Ma5M && Close[1] < Ma1M ){filter = 12;}
   if(Close[1] < Ma1H && Close[1] < Ma15M && Close[1] >= Ma5M && Close[1] >= Ma1M ){filter = 13;}
   if(Close[1] < Ma1H && Close[1] < Ma15M && Close[1] >= Ma5M && Close[1] < Ma1M ){filter = 14;}
   if(Close[1] < Ma1H && Close[1] < Ma15M && Close[1] < Ma5M && Close[1] >= Ma1M ){filter = 15;}
   if(Close[1] < Ma1H && Close[1] < Ma15M && Close[1] < Ma5M && Close[1] < Ma1M ){filter = 16;}

   

   
    

   //オープンポジションの計算
   int pos = CalculateCurrentOrders();

//以下はエントリールールが記載されているところ
//ロジック詳細
//40本の高値or安値のSlow_Periodの方でブレイクでエントリー
//決済は２０本のFast_Periodで確定。
//
//▼▼▼▼▼▼以下はエントリー処理▼▼▼▼▼▼▼
   //買いシグナル
   if(pos <= 0 && Close[2] <= SlowHH && Close[1] > SlowHH)
   {
      ClosePositions();
      OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"",MAGIC,0,Blue);
      return(0);
   }
   //売りシグナル
   if(pos >= 0 && Close[2] >= SlowLL && Close[1] < SlowLL)
   {
      ClosePositions();
      OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"",MAGIC,0,Red);
      return(0);
   }
   
//▼▼▼▼▼▼▼▼以下は決済処理▼▼▼▼▼▼
   //買いポジションを決済する
   if(pos > 0 && Close[2] >= FastLL && Close[1] < FastLL)
   {
      ClosePositions();
      printf("/////フィルター/////" +filter + "/////ロング/////" + "/////損益pipsは右/////" + OrderProfit());
      return(0);
   }
   //売りポジションを決済する
   if(pos < 0 && Close[2] <= FastHH && Close[1] > FastHH)
   {
      ClosePositions();
      printf("/////フィルター/////" +filter + "/////ショート/////" + "/////損益pipsは右/////" + OrderProfit());
      return(0);
   }
}
//+------------------------------------------------------------------+