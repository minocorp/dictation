public import SwiftUI

public struct SettingsView: View {
    @Bindable
    var model: SettingsWindowModel

    public init(model: SettingsWindowModel) {
        self.model = model
    }

    public var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, id: \.self, selection: $model.selection) { pane in
                Label {
                    Text(pane.title)
                } icon: {
                    Image(systemName: pane.symbol)
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 230)
        } detail: {
            SettingsDetail(model: model)
                .navigationTitle(Text(model.selection.title))
        }
        .frame(minWidth: 680, minHeight: 440)
        .task { await model.settings.refresh() }
    }
}
