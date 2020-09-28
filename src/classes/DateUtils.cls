public with sharing class DateUtils {

    public static String getMonth(Date d, String format) {
        Datetime dt = dateToDatetime(d);
        return dt.format(format);
    }

    public static String getFirstDayOfMonth(Date d, String format) {
        Datetime dt = dateToDatetime(getFirstDayOfMonth(d));
        return dt.format(format);
    }

    public static String getLastDayOfMonth(Date d, String format) {
        Datetime dt = dateToDatetime(getLastDayOfMonth(d));
        return dt.format(format);
    }

    public static Date getFirstDayOfMonth(Date d) {
        return Date.newInstance(d.year(), d.month(), 1);
    }

    public static Date getLastDayOfMonth(Date d) {
        return Date.newInstance(d.year(), d.month(), Date.daysInMonth(d.year(), d.month()));
    }

    public static Datetime dateToDatetime(Date d) {
        return Datetime.newInstance(d, createZeroTime());
    }

    private static Time createZeroTime() {
        return Time.newInstance(0, 0, 0, 0);
    }
}