import Core
import SwiftUI

internal struct ModelPickerRow: View {
    let model: ModelsModel
    let stage: ModelStage
    let title: LocalizedStringResource

    var body: some View {
        let selected = model.selected(stage)
        VStack(alignment: .leading, spacing: 6) {
            Picker(
                selection: Binding(
                    get: { selected.id },
                    set: { id in
                        if let entry = model.entries(stage).first(where: { $0.id == id }) {
                            model.select(entry)
                        }
                    },
                )
            ) {
                ForEach(model.entries(stage)) { entry in
                    Text(verbatim: model.optionTitle(entry)).tag(entry.id)
                }
            } label: {
                Text(title)
            }
            ModelStatusLine(model: model, entry: selected)
        }
    }
}
