// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QtTest>
#include "datetimeutils.h"

class TestDateTimeUtils : public QObject
{
    Q_OBJECT

private slots:
    void dateTimeFormat_returnsExpectedPattern();

    void formatDateTime_validDateTime();
    void formatDateTime_invalidDateTime_returnsEmpty();
    void formatDateTime_preservesMinutes();

    void parseDateTime_validString();
    void parseDateTime_invalidString_returnsInvalid();
    void parseDateTime_trailingWhitespace();
    void parseDateTime_wrongFormat_returnsInvalid();
    void parseDateTime_roundTrip();
};

// ── dateTimeFormat ────────────────────────────────────────────────────────────

void TestDateTimeUtils::dateTimeFormat_returnsExpectedPattern()
{
    DateTimeUtils utils;
    QCOMPARE(utils.dateTimeFormat(), QStringLiteral("dd/MM/yyyy HH:mm"));
}

// ── formatDateTime ────────────────────────────────────────────────────────────

void TestDateTimeUtils::formatDateTime_validDateTime()
{
    DateTimeUtils utils;
    QDateTime dt(QDate(2026, 3, 29), QTime(14, 5));
    QCOMPARE(utils.formatDateTime(dt), QStringLiteral("29/03/2026 14:05"));
}

void TestDateTimeUtils::formatDateTime_invalidDateTime_returnsEmpty()
{
    DateTimeUtils utils;
    QCOMPARE(utils.formatDateTime(QDateTime()), QString());
}

void TestDateTimeUtils::formatDateTime_preservesMinutes()
{
    DateTimeUtils utils;
    // Single-digit minutes must be zero-padded.
    QDateTime dt(QDate(2026, 1, 7), QTime(9, 3));
    QCOMPARE(utils.formatDateTime(dt), QStringLiteral("07/01/2026 09:03"));
}

// ── parseDateTime ─────────────────────────────────────────────────────────────

void TestDateTimeUtils::parseDateTime_validString()
{
    DateTimeUtils utils;
    QDateTime result = utils.parseDateTime("29/03/2026 14:05");
    QVERIFY(result.isValid());
    QCOMPARE(result.date(), QDate(2026, 3, 29));
    QCOMPARE(result.time(), QTime(14, 5));
}

void TestDateTimeUtils::parseDateTime_invalidString_returnsInvalid()
{
    DateTimeUtils utils;
    QVERIFY(!utils.parseDateTime("not a date").isValid());
    QVERIFY(!utils.parseDateTime("").isValid());
}

void TestDateTimeUtils::parseDateTime_trailingWhitespace()
{
    DateTimeUtils utils;
    QDateTime result = utils.parseDateTime("  29/03/2026 14:05  ");
    QVERIFY(result.isValid());
    QCOMPARE(result.date(), QDate(2026, 3, 29));
    QCOMPARE(result.time(), QTime(14, 5));
}

void TestDateTimeUtils::parseDateTime_wrongFormat_returnsInvalid()
{
    DateTimeUtils utils;
    // ISO format — not the canonical format dd/MM/yyyy HH:mm
    QVERIFY(!utils.parseDateTime("2026-03-29 14:05").isValid());
    // Date only, missing time
    QVERIFY(!utils.parseDateTime("29/03/2026").isValid());
}

void TestDateTimeUtils::parseDateTime_roundTrip()
{
    DateTimeUtils utils;
    const QDateTime original(QDate(2026, 12, 31), QTime(23, 59));
    const QString   formatted = utils.formatDateTime(original);
    const QDateTime parsed    = utils.parseDateTime(formatted);
    QCOMPARE(parsed, original);
}

QTEST_MAIN(TestDateTimeUtils)
#include "tst_datetimeutils.moc"
