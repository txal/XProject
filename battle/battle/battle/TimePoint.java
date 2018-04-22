package com.nucleus.logic.core.modules.battle;

import java.sql.Timestamp;
import java.util.Calendar;
import java.util.Date;

import org.apache.commons.lang3.time.DateUtils;

/**
 * 时间点
 * 
 * @author Tony
 * 
 */
public class TimePoint {
	private static final String H = "时";
	private static final String M = "分"; 
	public int hour;
	public int minute;

	public static TimePoint from(long timeInMillis) {
		Calendar cal = Calendar.getInstance();
		cal.setTimeInMillis(timeInMillis);
		TimePoint tp = new TimePoint();
		tp.hour = cal.get(Calendar.HOUR_OF_DAY);
		tp.minute = cal.get(Calendar.MINUTE);
		return tp;
	}
	
	public static String formatHourMinute(long millis) {
		int hour = (int) (millis / DateUtils.MILLIS_PER_HOUR);
		int minutes = (int) Math.ceil(millis % DateUtils.MILLIS_PER_HOUR / (double) DateUtils.MILLIS_PER_MINUTE);
		String str = hour + H + minutes + M;
		return str;
	}
	
	public TimePoint() {
	}

	public TimePoint(int hour, int minute) {
		this.hour = hour;
		this.minute = minute;
	}

	public Timestamp todayTimesatmp() {
		long millis = todayMillis();
		return new Timestamp(millis);
	}

	public Date today() {
		long millis = todayMillis();
		return new Date(millis);
	}

	public long todayMillis() {
		Calendar cal = Calendar.getInstance();
		cal.set(Calendar.HOUR_OF_DAY, hour);
		cal.set(Calendar.MINUTE, minute);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		return cal.getTimeInMillis();
	}

	public Date nextDay() {
		Date today = today();
		return DateUtils.addDays(today, 1);
	}

	public static TimePoint fromDataString(String timeString) {
		String[] data = timeString.split(":");
		return new TimePoint(Integer.valueOf(data[0]), Integer.valueOf(data[1]));
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder("" + hour);
		sb.append(":");
		if (minute < 10) {
			sb.append("0").append(minute);
		} else {
			sb.append(minute);
		}
		return sb.toString();
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + hour;
		result = prime * result + minute;
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		TimePoint other = (TimePoint) obj;
		if (hour != other.hour)
			return false;
		if (minute != other.minute)
			return false;
		return true;
	}
}
