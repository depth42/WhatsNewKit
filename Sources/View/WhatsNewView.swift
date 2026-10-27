import SwiftUI

// MARK: - WhatsNewView

/// A WhatsNewView
public struct WhatsNewView {
    
    // MARK: Properties
    
    /// The WhatsNew object
    private let whatsNew: WhatsNew
    
    /// The WhatsNewVersionStore
    private let whatsNewVersionStore: WhatsNewVersionStore?
    
    /// The WhatsNew Layout
    private let layout: WhatsNew.Layout
    
    /// The View that is presented by the SecondaryAction
    @State
    private var secondaryActionPresentedView: WhatsNew.SecondaryAction.Action.PresentedView?
    
    /// The PresentationMode
    @Environment(\.presentationMode)
    private var presentationMode
    
    // MARK: Initializer
    
    /// Creates a new instance of `WhatsNewView`
    /// - Parameters:
    ///   - whatsNew: The WhatsNew object
    ///   - versionStore: The optional WhatsNewVersionStore. Default value `nil`
    ///   - layout: The WhatsNew Layout. Default value `.default`
    public init(
        whatsNew: WhatsNew,
        versionStore: WhatsNewVersionStore? = nil,
        layout: WhatsNew.Layout = .default
    ) {
        self.whatsNew = whatsNew
        self.whatsNewVersionStore = versionStore
        self.layout = layout
    }
    
}

// MARK: - View

extension WhatsNewView: View {
    
    /// The content and behavior of the view.
    public var body: some View {
        self.layoutedContent
            .sheet(
                item: self.$secondaryActionPresentedView,
                content: { $0.view }
            )
            .onDisappear {
                // Save presented WhatsNew Version, if available
                self.whatsNewVersionStore?.save(
                    presentedVersion: self.whatsNew.version
                )
            }
    }
    
}

// MARK: - Layouted Content

private extension WhatsNewView {
    
    /// The ScrollView with the footer below it.
    /// Type-erased, as `ViewBuilder` can't branch on the availability of `safeAreaInset`.
    var layoutedContent: AnyView {
        if #available(iOS 15.0, macOS 12.0, visionOS 1.0, *) {
            // The footer takes the room it needs above the bottom safe area,
            // and the ScrollView ends where the footer begins
            return AnyView(
                self.scrollView(
                    bottomContentInset: 0
                )
                .safeAreaInset(
                    edge: .bottom,
                    spacing: 0
                ) {
                    self.footerContainer(
                        isAboveBottomSafeArea: true
                    )
                }
            )
        } else {
            return AnyView(
                ZStack {
                    // Content ScrollView
                    self.scrollView(
                        bottomContentInset: self.layout.scrollViewBottomContentInset
                    )
                    // Footer
                    VStack {
                        Spacer()
                        self.footerContainer(
                            isAboveBottomSafeArea: false
                        )
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            )
        }
    }
    
    /// The content ScrollView
    /// - Parameter bottomContentInset: The room left below the content for the footer
    func scrollView(
        bottomContentInset: CGFloat
    ) -> some View {
        ScrollView(
            .vertical,
            showsIndicators: self.layout.showsScrollViewIndicators
        ) {
            // Content Stack
            VStack(
                spacing: self.layout.contentSpacing
            ) {
                // Title
                self.title
                // Feature List
                VStack(
                    alignment: .leading,
                    spacing: self.layout.featureListSpacing
                ) {
                    // Feature
                    ForEach(
                        self.whatsNew.features,
                        id: \.self,
                        content: self.feature
                    )
                }
                .modifier(FeaturesPadding())
                .padding(self.layout.featureListPadding)
            }
            .padding(.horizontal)
            .padding(self.layout.contentPadding)
            // ScrollView bottom content inset
            Color.clear
                .padding(
                    .bottom,
                    bottomContentInset
                )
        }
        #if os(iOS)
        .alwaysBounceVertical(false)
        #endif
    }
    
    /// The footer with its padding and background
    /// - Parameter isAboveBottomSafeArea: Whether the footer is placed above the bottom safe area,
    ///   or measured from the bottom edge of the screen
    func footerContainer(
        isAboveBottomSafeArea: Bool
    ) -> some View {
        self.footer
            .modifier(
                FooterPadding(
                    isAboveBottomSafeArea: isAboveBottomSafeArea
                )
            )
            #if os(iOS)
            .background(
                UIVisualEffectView
                    .Representable()
                    .edgesIgnoringSafeArea(
                        isAboveBottomSafeArea ? [.horizontal, .bottom] : .horizontal
                    )
                    .padding(self.layout.footerVisualEffectViewPadding)
            )
            #endif
    }
    
}

// MARK: - Title

private extension WhatsNewView {
    
    /// The Title View
    var title: some View {
        Text(
            whatsNewText: self.whatsNew.title.text
        )
        .font(.largeTitle.bold())
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    
}

// MARK: - Feature

private extension WhatsNewView {
    
    /// The Feature View
    /// - Parameter feature: A WhatsNew Feature
    func feature(
        _ feature: WhatsNew.Feature
    ) -> some View {
        HStack(
            alignment: self.layout.featureHorizontalAlignment,
            spacing: self.layout.featureHorizontalSpacing
        ) {
            feature
                .image
                .view()
                .frame(width: self.layout.featureImageWidth)
            VStack(
                alignment: .leading,
                spacing: self.layout.featureVerticalSpacing
            ) {
                Text(
                    whatsNewText: feature.title
                )
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                Text(
                    whatsNewText: feature.subtitle
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
        }.accessibilityElement(children: .combine)
    }
    
}

// MARK: - Footer

private extension WhatsNewView {
    
    /// The Footer View
    var footer: some View {
        VStack(
            spacing: self.layout.footerActionSpacing
        ) {
            // Check if a secondary action is available
            if let secondaryAction = self.whatsNew.secondaryAction {
                // Secondary Action Button
                Button(
                    action: {
                        // Invoke HapticFeedback, if available
                        secondaryAction.hapticFeedback?()
                        // Switch on Action
                        switch secondaryAction.action {
                        case .present(let view):
                            // Set secondary action presented view
                            self.secondaryActionPresentedView = .init(view: view)
                        case .custom(let action):
                            // Invoke action with PresentationMode
                            action(self.presentationMode)
                        }
                    }
                ) {
                    Text(
                        whatsNewText: secondaryAction.title
                    )
                }
                #if os(macOS)
                .buttonStyle(
                    PlainButtonStyle()
                )
                #endif
                .foregroundColor(secondaryAction.foregroundColor)
            }
            // Primary Action Button
            Button(
                action: {
                    // Invoke HapticFeedback, if available
                    self.whatsNew.primaryAction.hapticFeedback?()
                    // Dismiss
                    self.presentationMode.wrappedValue.dismiss()
                    // Invoke on dismiss, if available
                    self.whatsNew.primaryAction.onDismiss?()
                }
            ) {
                Text(
                    whatsNewText: self.whatsNew.primaryAction.title
                )
            }
            .buttonStyle(
                PrimaryButtonStyle(
                    primaryAction: self.whatsNew.primaryAction,
                    layout: self.layout
                )
            )
            #if os(macOS)
            .keyboardShortcut(.defaultAction)
            #endif
        }
    }
    
}
