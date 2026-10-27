import SwiftUI

// MARK: - WhatsNewView+FooterPadding

extension WhatsNewView {
    
    /// The WhatsNewView FooterPadding ViewModifier
    struct FooterPadding {
        
        /// Whether the footer is placed above the bottom safe area (`safeAreaInset`),
        /// or measured from the bottom edge of the screen
        let isAboveBottomSafeArea: Bool
        
        #if os(iOS) || os(visionOS)
        /// The Horizontal SizeClass
        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass

        /// The Vertical SizeClass
        @Environment(\.verticalSizeClass)
        private var verticalSizeClass
        #endif
        
        /// Creates a new instance of `WhatsNewView.FooterPadding`
        /// - Parameter isAboveBottomSafeArea: Whether the footer is placed above the bottom safe area. Default value `false`
        init(
            isAboveBottomSafeArea: Bool = false
        ) {
            self.isAboveBottomSafeArea = isAboveBottomSafeArea
        }
        
    }
    
}

// MARK: - ViewModifier

extension WhatsNewView.FooterPadding: ViewModifier {
    
    /// Gets the current body of the caller.
    /// - Parameter content: The Content
    func body(
        content: Content
    ) -> some View {
        #if os(macOS)
        content.padding(.bottom, 30)
        #else
        if self.horizontalSizeClass == .regular {
            content.padding(
                .init(
                    top: 0,
                    leading: 150,
                    bottom: self.isAboveBottomSafeArea ? 30 : 50,
                    trailing: 150
                )
            )
        } else if self.verticalSizeClass == .compact {
            content.padding(
                .init(
                    top: 0,
                    leading: 40,
                    bottom: self.isAboveBottomSafeArea ? 20 : 35,
                    trailing: 40
                )
            )
        } else {
            content.padding(
                .init(
                    top: 0,
                    leading: 20,
                    bottom: self.isAboveBottomSafeArea ? 46 : 80,
                    trailing: 20
                )
            )
        }
        #endif
    }
    
}
