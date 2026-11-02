import SwiftUI
@main struct BachCuteCalendarApp: App {
 var body: some Scene {
  WindowGroup {
   VStack(spacing: 20) {
    Text("🌷 Bách Cute Calendar").font(.largeTitle.bold())
    Text("Mỗi ngày một chút dễ thương!")
    Text("🛌  🧎  🚶  🏃  🎉").font(.title)
    Text("Nhấn giữ màn hình chính, chọn Thêm tiện ích, tìm Bách Cute Calendar.")
     .multilineTextAlignment(.center)
   }.padding().frame(maxWidth: .infinity,maxHeight: .infinity)
    .background(Color(red: 0.98, green: 0.93, blue: 0.94))
  }
 }
}