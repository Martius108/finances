//
//  TotalExtractor.swift
//  Finances
//
//  Created by Martin Lanius on 29.05.25.
//

import Foundation

class TotalExtractor {

    func extractGrossTotal(from text: String) -> Double? {
        let lines = text
            .lowercased()
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Primary keywords
        let keywordRegex = try? NSRegularExpression(pattern: #"(?i)\b(summe|zu zahlen|total|zws-summe|endsumme|gesamt|betrag|zwischensumme|gesamtsumme)\b"#)
        // Matches numbers with either comma or dot as decimal separator, allowing thousand separators and spaces
        let priceRegex   = try? NSRegularExpression(pattern: #"\d{1,3}(?:[ .]\d{3})*\s*[.,]\s*\d{2}"#)

        for (i, line) in lines.enumerated() {
            let lower = line.lowercased()
            // Exclude "Gesamtsumme" when used in a tax summary block (contains "ust", "%", "netto" or "brutto")
            if lower.contains("gesamtsumme") && (lower.contains("ust") || lower.contains("%") || lower.contains("netto") || lower.contains("brutto")) {
                continue
            }
            // Sonderfall: Trinkgeld/Tip unter der Summe
            if let pr = priceRegex,
               let sumMatch = pr.firstMatch(in: line, options: [], range: NSRange(line.startIndex..<line.endIndex, in: line)),
               let sumRange = Range(sumMatch.range, in: line) {
                // Extrahiere Basis-Summe Y
                let rawSum = String(line[sumRange]).replacingOccurrences(of: " ", with: "")
                let yClean = rawSum.contains(",")
                    ? rawSum.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                    : rawSum
                guard let y = Double(yClean) else { break }

                // Prüfe zwei folgende Zeilen: Trinkgeld/Tip und Gesamt
                if i + 2 < lines.count {
                    let tipLine = lines[i + 1].lowercased()
                    let totalLine = lines[i + 2]

                    if tipLine.contains("trinkgeld") || tipLine.contains("tip") {
                        // Try normal tip match
                        var xValue: Double?
                        if let tipMatch = pr.firstMatch(in: tipLine, options: [], range: NSRange(tipLine.startIndex..<tipLine.endIndex, in: tipLine)),
                           let tipRange = Range(tipMatch.range, in: tipLine) {
                            let rawTip = String(tipLine[tipRange]).replacingOccurrences(of: " ", with: "")
                            let cleanedTip = rawTip.contains(",")
                                ? rawTip.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                                : rawTip
                            xValue = Double(cleanedTip)
                        } else {
                            // Fallback: match patterns like "1 17"
                            let fallbackTipPattern = try? NSRegularExpression(pattern: #"(\d+)\s+(\d{2})"#)
                            if let ftr = fallbackTipPattern,
                               let fb = ftr.firstMatch(in: tipLine, options: [], range: NSRange(tipLine.startIndex..<tipLine.endIndex, in: tipLine)),
                               let r1 = Range(fb.range(at: 1), in: tipLine),
                               let r2 = Range(fb.range(at: 2), in: tipLine) {
                                let part1 = String(tipLine[r1]), part2 = String(tipLine[r2])
                                xValue = Double(part1 + "." + part2)
                            }
                        }
                        if let x = xValue,
                           let totalMatch = pr.firstMatch(in: totalLine, options: [], range: NSRange(totalLine.startIndex..<totalLine.endIndex, in: totalLine)),
                           let totalRange = Range(totalMatch.range, in: totalLine) {
                            let rawTotal = String(totalLine[totalRange]).replacingOccurrences(of: " ", with: "")
                            let cleanedTotal = rawTotal.contains(",")
                                ? rawTotal.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                                : rawTotal
                            if let z = Double(cleanedTotal), z > y {
                                return z
                            }
                        }
                    }
                }
            }
            // If this line contains our keyword
            if let kr = keywordRegex,
               kr.firstMatch(in: line, options: [], range: NSRange(line.startIndex..<line.endIndex, in: line)) != nil {
                // 1) Try inline price in same line (use last match to avoid VAT values)
                if let pr = priceRegex {
                    let matches = pr.matches(in: line, options: [], range: NSRange(line.startIndex..<line.endIndex, in: line))
                    if let lastMatch = matches.last,
                       let r = Range(lastMatch.range, in: line) {
                        let raw = String(line[r])
                        // Remove spaces
                        var cleaned = raw.replacingOccurrences(of: " ", with: "")
                        if cleaned.contains(",") {
                            cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
                        }
                        return Double(cleaned)
                    }
                }

                // 2) Fallback: scan subsequent lines for a standalone price
                for nextIndex in (lines.firstIndex(of: line)! + 1)..<lines.count {
                    let nextLine = lines[nextIndex]
                    let nsRangeNext = NSRange(nextLine.startIndex..<nextLine.endIndex, in: nextLine)
                    if let pr = priceRegex,
                       let matchNext = pr.firstMatch(in: nextLine, options: [], range: nsRangeNext),
                       let rNext = Range(matchNext.range, in: nextLine) {
                        let rawNext = String(nextLine[rNext])
                        var cleanedNext = rawNext.replacingOccurrences(of: " ", with: "")
                        if cleanedNext.contains(",") {
                            cleanedNext = cleanedNext.replacingOccurrences(of: ".", with: "")
                            cleanedNext = cleanedNext.replacingOccurrences(of: ",", with: ".")
                        }
                        return Double(cleanedNext)
                    }
                }

                // No price found for this keyword line
                return nil
            }
        }
        return nil
    }
}
