// AboutView.swift

import AppKit
import SwiftUI

struct AboutView: View {
    @EnvironmentObject var router: Router
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.4"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "6"
        return "版本 \(version) (\(build))"
    }

    private var appIcon: NSImage {
        NSImage(named: NSImage.applicationIconName) ?? NSApp.applicationIconImage ?? NSImage()
    }

    var body: some View {
        VStack(spacing: 0) {
            Titlebar()

            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    // 应用图标与名称
                    VStack(spacing: 8) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

                        Text("Timefolk")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        Text(versionString)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            )

                        Text("优雅跨越时区的世界时钟与朋友作息罗盘")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 4)

                    // 信息列表卡片
                    VStack(spacing: 0) {
                        infoRow(title: "开源源码", value: "GitHub 仓库", icon: "link") {
                            if let url = URL(string: "https://github.com/scavin/Timefolk") {
                                openURL(url)
                            }
                        }

                        Divider()
                            .padding(.horizontal, 10)

                        infoRow(title: "运行架构", value: "Apple Silicon (arm64)", icon: "cpu")

                        Divider()
                            .padding(.horizontal, 10)

                        infoRow(title: "开源许可", value: "MIT License", icon: "doc.text")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                            .fill(TimefolkTheme.Colors.cardBackground(colorScheme: scheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                            .strokeBorder(TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)

                    // 返回按钮
                    SecondaryButton(title: "返回") {
                        withAnimation(TimefolkTheme.Animation.quick) {
                            router.cleanActiveRoute()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func infoRow(title: String, value: String, icon: String, action: (() -> Void)? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            if let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(value)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
    }
}

#Preview {
    AboutView()
        .frame(width: 320, height: 360)
        .environmentObject(Router())
}
