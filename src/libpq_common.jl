macro c(ret_type, func, arg_types, lib)
    local args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
    quote
        $(esc(func))($(args_in...)) = ccall( ($(string(func)), $(Expr(:quote, lib)) ), 
                                            $ret_type, $arg_types, $(args_in...) )
    end
end


const unix = 1
const linux = 1
const EOF = (-1)
# Skipping MacroDefinition: NULL((void*)0)
const BUFSIZ = 
const SEEK_SET = 0
const SEEK_CUR = 1
const SEEK_END = 2
const P_tmpdir = "/tmp"
const L_tmpnam = 20
const TMP_MAX = 238328
const FILENAME_MAX = 4096
const L_ctermid = 9
const FOPEN_MAX = 16
const stdin = 
const stdout = 
const stderr = 
# Skipping MacroDefinition: getc(_fp)_IO_getc(_fp)
# Skipping MacroDefinition: putc(_ch,_fp)_IO_putc(_ch,_fp)
# Skipping MacroDefinition: InvalidOid((Oid)0)
const OID_MAX = 
const PG_DIAG_SEVERITY = 'S'
const PG_DIAG_SQLSTATE = 'C'
const PG_DIAG_MESSAGE_PRIMARY = 'M'
const PG_DIAG_MESSAGE_DETAIL = 'D'
const PG_DIAG_MESSAGE_HINT = 'H'
const PG_DIAG_STATEMENT_POSITION = 'P'
const PG_DIAG_INTERNAL_POSITION = 'p'
const PG_DIAG_INTERNAL_QUERY = 'q'
const PG_DIAG_CONTEXT = 'W'
const PG_DIAG_SOURCE_FILE = 'F'
const PG_DIAG_SOURCE_LINE = 'L'
const PG_DIAG_SOURCE_FUNCTION = 'R'
const PG_COPYRES_ATTRS = 0x01
const PG_COPYRES_TUPLES = 0x02
const PG_COPYRES_EVENTS = 0x04
const PG_COPYRES_NOTICEHOOKS = 0x08
# manually added pg formats
const PGF_TEXT = 0
const PGF_BINARY = 1
# Skipping MacroDefinition: PQsetdb(M_PGHOST,M_PGPORT,M_PGOPT,M_PGTTY,M_DBNAME)PQsetdbLogin(M_PGHOST,M_PGPORT,M_PGOPT,M_PGTTY,M_DBNAME,NULL,NULL)
# Skipping MacroDefinition: PQfreeNotify(ptr)PQfreemem(ptr)
const PQnoPasswordSupplied = "fe_sendauth: no password supplied\n"
typealias _IO_lock_t None
typealias va_list Cint
# typealias off_t __off_t
# typealias ssize_t __ssize_t
# typealias fpos_t _G_fpos_t
typealias Oid Uint32
# begin enum ConnStatusType
typealias ConnStatusType Uint32
const CONNECTION_OK = 0
const CONNECTION_BAD = 1
const CONNECTION_STARTED = 2
const CONNECTION_MADE = 3
const CONNECTION_AWAITING_RESPONSE = 4
const CONNECTION_AUTH_OK = 5
const CONNECTION_SETENV = 6
const CONNECTION_SSL_STARTUP = 7
const CONNECTION_NEEDED = 8
# end enum ConnStatusType
# begin enum PostgresPollingStatusType
typealias PostgresPollingStatusType Uint32
const PGRES_POLLING_FAILED = 0
const PGRES_POLLING_READING = 1
const PGRES_POLLING_WRITING = 2
const PGRES_POLLING_OK = 3
const PGRES_POLLING_ACTIVE = 4
# end enum PostgresPollingStatusType
# begin enum ExecStatusType
typealias ExecStatusType Uint32
const PGRES_EMPTY_QUERY = 0
const PGRES_COMMAND_OK = 1
const PGRES_TUPLES_OK = 2
const PGRES_COPY_OUT = 3
const PGRES_COPY_IN = 4
const PGRES_BAD_RESPONSE = 5
const PGRES_NONFATAL_ERROR = 6
const PGRES_FATAL_ERROR = 7
const PGRES_COPY_BOTH = 8
const PGRES_SINGLE_TUPLE = 9
# end enum ExecStatusType
# begin enum PGTransactionStatusType
typealias PGTransactionStatusType Uint32
const PQTRANS_IDLE = 0
const PQTRANS_ACTIVE = 1
const PQTRANS_INTRANS = 2
const PQTRANS_INERROR = 3
const PQTRANS_UNKNOWN = 4
# end enum PGTransactionStatusType
# begin enum PGVerbosity
typealias PGVerbosity Uint32
const PQERRORS_TERSE = 0
const PQERRORS_DEFAULT = 1
const PQERRORS_VERBOSE = 2
# end enum PGVerbosity
# begin enum PGPing
typealias PGPing Uint32
const PQPING_OK = 0
const PQPING_REJECT = 1
const PQPING_NO_RESPONSE = 2
const PQPING_NO_ATTEMPT = 3
# end enum PGPing
typealias PQnoticeReceiver Ptr{Void}
typealias PQnoticeProcessor Ptr{Void}
typealias pqbool Uint8
typealias pgthreadlock_t Ptr{Void}
typealias PGconn Void
typealias PGresult Void
