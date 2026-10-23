import SwiftUI
import UserNotifications

struct FormSection: View {
    @Binding var name: String
    @Binding var city: String
    @Binding var selectedTimeZone: TimeZone?
    @Binding var isShowingPopover: Bool
    @StateObject var searchCompleter: SearchCompleter
    @Binding var image: NSImage?
    @Binding var showingTGAccountInput: Bool
    @Binding var showingXAccountInput: Bool
    @State var showError: Bool = false
    @State private var username = ""
    @State private var debounceTask: Task<Void, Never>?
    var isEditing: Bool = false
    var saveError: String?
    var onDelete: (() -> Void)? = nil
    let saveEntry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                StyledLabel(title: "朋友称呼")
                Input(text: $name, placeholder: "比如：阿杰、伦敦办公室", icon: "person")
                    .onSubmit {
                        if !city.isEmpty && selectedTimeZone != nil {
                            saveEntry()
                        } else {
                            withAnimation(TimefolkTheme.Animation.quick) {
                                showError = true
                            }
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                StyledLabel(title: "所在城市")
                
                Button {
                    withAnimation(TimefolkTheme.Animation.quick) {
                        showError = false
                    }
                    isShowingPopover = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(city.isEmpty ? .secondary : .accentColor)

                        Text(city.isEmpty ? "选择城市" : city)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(city.isEmpty ? .secondary : .primary)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .popover(isPresented: $isShowingPopover) {
                    CitySearchResults(
                        searchCompleter: searchCompleter,
                        isShowingPopover: $isShowingPopover,
                        selectedName: $name,
                        selectedCity: $city,
                        selectedTimezone: $selectedTimeZone,
                        image: $image
                    )
                }
            }

            if showError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text("请先选好朋友所在城市")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.red)
                .transition(.opacity)
            }

            if let saveError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(saveError)
                        .font(.system(size: 11))
                }
                .foregroundColor(.red)
            }

            if isEditing, let onDelete {
                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Text("删除朋友")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    PrimaryButton(title: "保存", action: {
                        if !city.isEmpty && selectedTimeZone != nil {
                            saveEntry()
                        } else {
                            withAnimation(TimefolkTheme.Animation.quick) {
                                showError = true
                            }
                        }
                    })
                    .accessibilityIdentifier("timezone.save")
                    .disabled(city.isEmpty || selectedTimeZone == nil)
                }
                .padding(.top, 4)
            } else {
                PrimaryButton(title: "添加", action: {
                    if !city.isEmpty && selectedTimeZone != nil {
                        saveEntry()
                    } else {
                        withAnimation(TimefolkTheme.Animation.quick) {
                            showError = true
                        }
                    }
                })
                .accessibilityIdentifier("timezone.save")
                .disabled(city.isEmpty || selectedTimeZone == nil)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
    }
}
