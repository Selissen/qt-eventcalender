// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef DATETIMEUTILS_H
#define DATETIMEUTILS_H

#include <QDateTime>
#include <QObject>
#include <QString>
#include <QtQml>

class DateTimeUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit DateTimeUtils(QObject *parent = nullptr);

    // The canonical display/parse format used by DatePickerField ("dd/MM/yyyy HH:mm").
    Q_PROPERTY(QString dateTimeFormat READ dateTimeFormat CONSTANT)
    QString dateTimeFormat() const;

    // Format a QDateTime into the canonical display string.
    // Returns an empty string for an invalid dt.
    Q_INVOKABLE QString formatDateTime(const QDateTime &dt) const;

    // Parse a string produced (or typed) using the canonical format.
    // Returns an invalid QDateTime if the text cannot be parsed.
    Q_INVOKABLE QDateTime parseDateTime(const QString &text) const;
};

#endif // DATETIMEUTILS_H
