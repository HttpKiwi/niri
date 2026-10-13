pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

/**
 * ColombianHolidays - Colombia public holidays (fixed + Easter-based, Ley Emiliani).
 * Cached per year; keys are "YYYY-MM-DD".
 */
QtObject {
    id: root

    property var _cache: ({})

    function clearCache() {
        root._cache = {};
    }

    function pad2(n) {
        return n < 10 ? ("0" + n) : ("" + n);
    }

    function dateKeyFromParts(y, m, d) {
        return y + "-" + pad2(m) + "-" + pad2(d);
    }

    function dateKeyFromDate(dt) {
        return dateKeyFromParts(dt.getFullYear(), dt.getMonth() + 1, dt.getDate());
    }

    function addDays(dt, days) {
        const out = new Date(dt.getTime());
        out.setDate(out.getDate() + days);
        return out;
    }

    /** Move to the following Monday unless already Monday (Ley Emiliani). */
    function emilianiMonday(dt) {
        const wd = dt.getDay(); // 0 Sun .. 6 Sat
        if (wd === 1)
            return dt;
        const out = new Date(dt.getTime());
        if (wd === 0)
            out.setDate(out.getDate() + 1);
        else
            out.setDate(out.getDate() + (8 - wd));
        return out;
    }

    function easterSunday(year) {
        const a = year % 19;
        const b = Math.floor(year / 100);
        const c = year % 100;
        const d = Math.floor(b / 4);
        const e = b % 4;
        const f = Math.floor((b + 8) / 25);
        const g = Math.floor((b - f + 1) / 3);
        const h = (19 * a + b - d - g + 15) % 30;
        const i = Math.floor(c / 4);
        const k = c % 4;
        const l = (32 + 2 * e + 2 * i - h - k) % 7;
        const m = Math.floor((a + 11 * h + 22 * l) / 451);
        const month = Math.floor((h + l - 7 * m + 114) / 31);
        const day = ((h + l - 7 * m + 114) % 31) + 1;
        return new Date(year, month - 1, day);
    }

    function _add(map, dt, name) {
        const key = dateKeyFromDate(dt);
        if (map[key])
            map[key] += ", " + name;
        else
            map[key] = name;
    }

    function _fixed(map, year, month, day, name, emiliani) {
        let dt = new Date(year, month - 1, day);
        if (emiliani)
            dt = emilianiMonday(dt);
        _add(map, dt, name);
    }

    function holidaysForYear(year) {
        if (root._cache[year])
            return root._cache[year];

        const map = {};
        const easter = easterSunday(year);

        // Easter-linked (exact dates)
        _add(map, addDays(easter, -3), "Jueves Santo");
        _add(map, addDays(easter, -2), "Viernes Santo");

        // Easter-linked (observed Monday)
        _add(map, emilianiMonday(addDays(easter, 43)), "Ascensión del Señor");
        _add(map, emilianiMonday(addDays(easter, 60)), "Corpus Christi");
        _add(map, emilianiMonday(addDays(easter, 68)), "Sagrado Corazón");

        // Fixed — not moved
        _fixed(map, year, 1, 1, "Año Nuevo", false);
        _fixed(map, year, 5, 1, "Día del Trabajo", false);
        _fixed(map, year, 7, 20, "Independencia de Colombia", false);
        _fixed(map, year, 8, 7, "Batalla de Boyacá", false);
        _fixed(map, year, 12, 8, "Inmaculada Concepción", false);
        _fixed(map, year, 12, 25, "Navidad", false);

        // Fixed — Ley Emiliani (Monday)
        _fixed(map, year, 1, 6, "Reyes Magos", true);
        _fixed(map, year, 3, 19, "San José", true);
        _fixed(map, year, 6, 29, "San Pedro y San Pablo", true);
        _fixed(map, year, 8, 15, "Asunción de la Virgen", true);
        _fixed(map, year, 10, 12, "Día de la Raza", true);
        _fixed(map, year, 11, 1, "Todos los Santos", true);
        _fixed(map, year, 11, 11, "Independencia de Cartagena", true);

        root._cache[year] = map;
        return map;
    }

    function nameOn(year, month, day) {
        const map = holidaysForYear(year);
        return map[dateKeyFromParts(year, month, day)] || "";
    }

    function isHoliday(year, month, day) {
        return nameOn(year, month, day) !== "";
    }

    function holidaysInMonth(year, month) {
        const map = holidaysForYear(year);
        const prefix = year + "-" + pad2(month) + "-";
        const out = [];
        for (const key in map) {
            if (key.startsWith(prefix))
                out.push({ date: key, name: map[key], day: parseInt(key.slice(8), 10) });
        }
        out.sort((a, b) => a.day - b.day);
        return out;
    }
}
