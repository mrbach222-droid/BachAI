import SwiftUI
import WidgetKit
struct CuteEntry: TimelineEntry { let date: Date }
struct CuteProvider: TimelineProvider {
 func placeholder(in context: Context) -> CuteEntry { CuteEntry(date: .now) }
 func getSnapshot(in context: Context, completion: @escaping (CuteEntry)->Void) { completion(CuteEntry(date: .now)) }
 func getTimeline(in context: Context, completion: @escaping (Timeline<CuteEntry>)->Void) {
  let c = Calendar.current
  let tomorrow = c.date(byAdding: .day,value: 1,to: c.startOfDay(for: .now))!
  completion(Timeline(entries: [CuteEntry(date: .now)],policy: .after(tomorrow)))
 }
}
struct CuteWidgetView: View {
 let entry: CuteEntry
 let names = ["T2","T3","T4","T5","T6","T7","CN"]
 let poses = ["🛌","🧎","🚶","🚶‍♀️","🏃","🎉","😴"]
 var index: Int { (Calendar.current.component(.weekday,from: entry.date)+5)%7 }
 var monday: Date { Calendar.current.date(byAdding: .day,value: -index,to: Calendar.current.startOfDay(for: entry.date))! }
 var heading: String {
  index == 4 ? "Thứ Sáu rồi, bung lụa thôi! 🎉" : index > 4 ? "Cuối tuần vui vẻ nha! 💕" : "Còn \(4-index) ngày nữa là Thứ Sáu"
 }
 var body: some View {
  VStack(spacing: 9) {
   Text(heading).font(.system(size: 17,weight: .semibold,design: .rounded)).lineLimit(1).minimumScaleFactor(0.65)
   HStack(spacing: 1) {
    ForEach(0..<7,id: \.self) { i in
     let date = Calendar.current.date(byAdding: .day,value: i,to: monday)!
     VStack(spacing: 5) {
      Text(poses[i]).font(.system(size: 25)).frame(height: 38)
      Text(names[i]).font(.system(size: 12,weight: .bold))
      Text(date,format: .dateTime.day().month(.twoDigits)).font(.system(size: 10)).minimumScaleFactor(0.6)
     }.frame(maxWidth: .infinity).padding(.vertical,4)
      .background(i == index ? Color.white.opacity(0.6) : Color.clear,in: RoundedRectangle(cornerRadius: 9))
    }
   }
  }.foregroundStyle(Color(red:0.25,green:0.28,blue:0.26)).padding(12)
   .containerBackground(Color(red:0.86,green:0.92,blue:0.84),for: .widget)
 }
}
struct BachCuteWidget: Widget {
 var body: some WidgetConfiguration {
  StaticConfiguration(kind:"BachCuteWidget",provider:CuteProvider()) { CuteWidgetView(entry:$0) }
   .configurationDisplayName("Bách Cute Calendar")
   .description("Lịch tuần dễ thương, đếm ngược tới thứ Sáu")
   .supportedFamilies([.systemMedium,.systemLarge])
 }
}
@main struct BachCuteWidgetBundle: WidgetBundle {
 var body: some Widget { BachCuteWidget() }
}