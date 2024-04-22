//
//  DateFormatStyle+Timezone.swift
//  Tempo
//
//  Created by Antony Nelson Daudt Alkmin on 22/04/24.
//

import Foundation

extension Date.FormatStyle {
    func withTimeZone(_ timeZone: TimeZone) -> Date.FormatStyle {
        var copy = self
        copy.timeZone = timeZone
        return copy
    }
}
