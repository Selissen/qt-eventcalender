// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "datetimeutils.h"

namespace {
    constexpr auto kFmt = "dd/MM/yyyy HH:mm";
}

DateTimeUtils::DateTimeUtils(QObject *parent) : QObject(parent) {}

QString DateTimeUtils::dateTimeFormat() const
{
    return QLatin1String(kFmt);
}

QString DateTimeUtils::formatDateTime(const QDateTime &dt) const
{
    if (!dt.isValid())
        return QString();
    return dt.toString(QLatin1String(kFmt));
}

QDateTime DateTimeUtils::parseDateTime(const QString &text) const
{
    return QDateTime::fromString(text.trimmed(), QLatin1String(kFmt));
}
