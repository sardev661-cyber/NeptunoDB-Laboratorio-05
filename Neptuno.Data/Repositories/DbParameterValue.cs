using System;
using System.Data;

namespace Neptuno.Data.Repositories
{
    public sealed class DbParameterValue
    {
        internal string Name { get; private set; }
        internal SqlDbType Type { get; private set; }
        internal object Value { get; private set; }
        internal int Size { get; private set; }
        internal byte Precision { get; private set; }
        internal byte Scale { get; private set; }

        private DbParameterValue(string name, SqlDbType type, object value, int size, byte precision, byte scale)
        {
            Name = name; Type = type; Value = value ?? DBNull.Value;
            Size = size; Precision = precision; Scale = scale;
        }

        public static DbParameterValue Text(string name, int size, string value)
        {
            object clean = string.IsNullOrWhiteSpace(value) ? (object)DBNull.Value : value.Trim();
            return new DbParameterValue(name, SqlDbType.NVarChar, clean, size, 0, 0);
        }

        public static DbParameterValue Integer(string name, object value)
        { return new DbParameterValue(name, SqlDbType.Int, value, 0, 0, 0); }

        public static DbParameterValue Date(string name, object value)
        { return new DbParameterValue(name, SqlDbType.Date, value, 0, 0, 0); }

        public static DbParameterValue Bit(string name, object value)
        { return new DbParameterValue(name, SqlDbType.Bit, value, 0, 0, 0); }

        public static DbParameterValue SmallInt(string name, object value)
        { return new DbParameterValue(name, SqlDbType.SmallInt, value, 0, 0, 0); }

        public static DbParameterValue Decimal(string name, object value)
        { return new DbParameterValue(name, SqlDbType.Decimal, value, 0, 10, 2); }
    }
}
