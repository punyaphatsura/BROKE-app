//
//  BROKETests.swift
//  BROKETests
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Testing
import Foundation
@testable import BROKE

struct AnalyticsHelpersTests {

    private func makeExpense(amount: Double, daysAgo: Int) -> Transaction {
        Transaction(
            amount: amount,
            description: "test",
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            type: .expense,
            source: .manual
        )
    }

    // MARK: - expenseTotals

    @Test func expenseTotals_currentMonthOnly() {
        let t = makeExpense(amount: 100, daysAgo: 0)
        let results = expenseTotals(from: [t], months: 1, referenceDate: Date())
        #expect(results.count == 1)
        #expect(results[0].total == 100)
    }

    @Test func expenseTotals_ignoresIncome() {
        var income = makeExpense(amount: 500, daysAgo: 0)
        income.type = .income
        let results = expenseTotals(from: [income], months: 1, referenceDate: Date())
        #expect(results[0].total == 0)
    }

    @Test func expenseTotals_returns12MonthsOldestFirst() {
        let results = expenseTotals(from: [], months: 12, referenceDate: Date())
        #expect(results.count == 12)
        #expect(results[0].month < results[11].month)
    }

    @Test func expenseTotals_zeroMonths_returnsEmpty() {
        let results = expenseTotals(from: [], months: 0, referenceDate: Date())
        #expect(results.isEmpty)
    }

    // MARK: - dailySpend

    @Test func dailySpend_sumsCorrectDay() {
        let t1 = makeExpense(amount: 200, daysAgo: 0)
        let t2 = makeExpense(amount: 300, daysAgo: 0)
        let result = dailySpend(from: [t1, t2], referenceDate: Date())
        let today = Calendar.current.component(.day, from: Date())
        #expect(result[today] == 500)
    }

    @Test func dailySpend_ignoresOtherMonths() {
        let today = Calendar.current.component(.day, from: Date())
        let t = makeExpense(amount: 999, daysAgo: today + 1)
        let result = dailySpend(from: [t], referenceDate: Date())
        #expect(result.values.reduce(0, +) == 0)
    }

    // MARK: - weekdayAverages

    @Test func weekdayAverages_allWeekdaysPresent() {
        let result = weekdayAverages(from: [], referenceDate: Date())
        #expect(result.count == 7)
    }

    @Test func weekdayAverages_averagesCorrectly() {
        let t1 = makeExpense(amount: 100, daysAgo: 0)
        let t2 = makeExpense(amount: 100, daysAgo: 0)
        let result = weekdayAverages(from: [t1, t2], referenceDate: Date())
        let todayWd = Calendar.current.component(.weekday, from: Date())
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let count = range.filter { day in
            let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            return calendar.component(.weekday, from: d) == todayWd
        }.count
        let expected = 200.0 / Double(count)
        #expect(abs((result[todayWd] ?? 0) - expected) < 0.01)
    }
}

struct AnnualExpenseTests {

    private func makeAnnual(amount: Double, year: Int) -> Transaction {
        var components = DateComponents()
        components.year = year
        components.month = 6
        components.day = 1
        let date = Calendar.current.date(from: components)!
        return Transaction(amount: amount, description: "annual test", date: date, type: .expense, source: .manual, isAnnual: true)
    }

    private func makeRegular(amount: Double) -> Transaction {
        Transaction(amount: amount, description: "regular", date: Date(), type: .expense, source: .manual)
    }

    @Test func annualExpenses_filtersAnnualOnly() {
        let a = makeAnnual(amount: 12000, year: 2025)
        let r = makeRegular(amount: 500)
        let result = annualExpenses(from: [a, r], year: 2025)
        #expect(result.count == 1)
        #expect(result[0].amount == 12000)
    }

    @Test func annualExpenses_filtersCorrectYear() {
        let a2025 = makeAnnual(amount: 12000, year: 2025)
        let a2024 = makeAnnual(amount: 5000, year: 2024)
        let result = annualExpenses(from: [a2025, a2024], year: 2025)
        #expect(result.count == 1)
        #expect(result[0].amount == 12000)
    }

    @Test func annualExpenses_ignoresIncomeWithAnnualFlag() {
        var income = makeAnnual(amount: 100000, year: 2025)
        income.type = .income
        let result = annualExpenses(from: [income], year: 2025)
        #expect(result.isEmpty)
    }

    @Test func annualExpenses_emptyWhenNone() {
        let result = annualExpenses(from: [makeRegular(amount: 100)], year: 2025)
        #expect(result.isEmpty)
    }
}
