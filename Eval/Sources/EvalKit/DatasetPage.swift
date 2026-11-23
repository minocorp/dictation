internal struct DatasetPage: Decodable {
    struct Entry: Decodable {
        let row: [String: RowValue]
    }

    enum CodingKeys: String, CodingKey {
        case rows
        case total = "num_rows_total"
    }

    let rows: [Entry]
    let total: Int
}
