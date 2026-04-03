import QtQuick
import App

// Computes the visible date range for the current view (month or week).
// Used by EventSidebar and PlanFooter to avoid duplicating this logic.
QtObject {
    required property date displayDate
    required property bool weekViewActive

    readonly property date rangeStart: {
        if (weekViewActive)
            return CalendarUtils.weekStart(displayDate, Qt.locale().firstDayOfWeek)
        return new Date(displayDate.getFullYear(), displayDate.getMonth(), 1)
    }

    readonly property date rangeEnd: {
        if (weekViewActive) {
            var s = CalendarUtils.weekStart(displayDate, Qt.locale().firstDayOfWeek)
            var e = new Date(s)
            e.setDate(e.getDate() + 6)
            return e
        }
        return new Date(displayDate.getFullYear(), displayDate.getMonth() + 1, 0)
    }
}
