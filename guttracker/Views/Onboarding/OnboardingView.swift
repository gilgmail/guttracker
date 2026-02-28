import SwiftUI

struct OnboardingPageData {
    let systemImage: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

private let pages: [OnboardingPageData] = [
    OnboardingPageData(
        systemImage: "plus.circle.fill",
        title: "3 秒記錄",
        description: "點選 Bristol 糞便類型，一鍵完成。血便、黏液、症狀選填。"
    ),
    OnboardingPageData(
        systemImage: "calendar",
        title: "每日回顧",
        description: "月曆查看每天記錄狀態。點選日期看當天完整詳情。"
    ),
    OnboardingPageData(
        systemImage: "chart.bar.fill",
        title: "趨勢分析",
        description: "7 / 30 / 90 天統計圖表，追蹤排便頻率與 Bristol 均值。"
    ),
]

struct OnboardingPageView: View {
    let page: OnboardingPageData

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Spacer().frame(height: 48)
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
            Spacer().frame(height: 16)
            Text(page.description)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.appTheme) private var theme
    @State private var currentPage = 0

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .automatic))

                Button {
                    withAnimation {
                        if isLastPage {
                            hasCompletedOnboarding = true
                        } else {
                            currentPage += 1
                        }
                    }
                } label: {
                    Text(isLastPage ? "開始使用" : "下一頁")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }

            Button("略過") {
                hasCompletedOnboarding = true
            }
            .foregroundStyle(.secondary)
            .padding()
        }
    }
}

#Preview {
    OnboardingView()
}
