# Julia wrapper for header: /usr/include/postgresql/libpq-fe.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

module libpq
           # types
    export PGconn,
           PGresult,
           Oid,
           # enums
           ConnStatusType,
           CONNECTION_OK,
           CONNECTION_BAD,
           CONNECTION_STARTED,
           CONNECTION_MADE,
           CONNECTION_AWAITING_RESPONSE,
           CONNECTION_AUTH_OK,
           CONNECTION_SETENV,
           CONNECTION_SSL_STARTUP,
           CONNECTION_NEEDED,
           ExecStatusType,
           PGRES_EMPTY_QUERY,
           PGRES_COMMAND_OK,
           PGRES_TUPLES_OK,
           PGRES_COPY_OUT,
           PGRES_COPY_IN,
           PGRES_BAD_RESPONSE,
           PGRES_NONFATAL_ERROR,
           PGRES_FATAL_ERROR,
           PGRES_COPY_BOTH,
           PGRES_SINGLE_TUPLE,
           PGTransactionStatusType,
           PQTRANS_IDLE,
           PQTRANS_ACTIVE,
           PQTRANS_INTRANS,
           PQTRANS_INERROR,
           PQTRANS_UNKNOWN,
           PGF_TEXT,
           PGF_BINARY,
           # connection functions
           PQconnectdb,
           PQconnectdbParams,
           PQsetdbLogin,
           PQfinish,
           PQreset,
           # connection status functions
           PQdb,
           PQuser,
           PQpass,
           PQhost,
           PQport,
           PQsocket,
           PQstatus,
           PQtransactionStatus,
           PQprotocolVersion,
           PQerrorMessage,
           # command execution functions
           PQexec,
           PQexecParams,
           PQprepare,
           PQexecPrepared,
           PQdescribePrepared,
           PQgetvalue,
           PQgetisnull,
           PQnparams,
           PQparamtype,
           PQntuples,
           PQnfields,
           PQftype,
           PQfname,
           PQgetlength,
           PQresStatus,
           PQresultStatus,
           PQresultErrorMessage,
           PQclear,
           # misc
           PQescapeLiteral,
           PQescapeIdentifier,
           PQfreemem

    include("libpq_common.jl")

    @c Cint _IO_getc (Ptr{_IO_FILE},) libpq
    @c Cint _IO_putc (Cint, Ptr{_IO_FILE}) libpq
    @c Cint _IO_feof (Ptr{_IO_FILE},) libpq
    @c Cint _IO_ferror (Ptr{_IO_FILE},) libpq
    @c Cint _IO_peekc_locked (Ptr{_IO_FILE},) libpq
    @c None _IO_flockfile (Ptr{_IO_FILE},) libpq
    @c None _IO_funlockfile (Ptr{_IO_FILE},) libpq
    @c Cint _IO_ftrylockfile (Ptr{_IO_FILE},) libpq
    @c Cint _IO_vfscanf (Ptr{_IO_FILE}, Ptr{Uint8}, Cint, Ptr{Cint}) libpq
    @c Cint _IO_vfprintf (Ptr{_IO_FILE}, Ptr{Uint8}, Cint) libpq
    # @c __ssize_t _IO_padn (Ptr{_IO_FILE}, Cint, __ssize_t) libpq
    @c Cint _IO_sgetn (Ptr{_IO_FILE}, Ptr{None}, Cint) libpq
    @c __off64_t _IO_seekoff (Ptr{_IO_FILE}, __off64_t, Cint, Cint) libpq
    @c __off64_t _IO_seekpos (Ptr{_IO_FILE}, __off64_t, Cint) libpq
    @c None _IO_free_backup_area (Ptr{_IO_FILE},) libpq
    @c Cint remove (Ptr{Uint8},) libpq
    @c Cint rename (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Cint renameat (Cint, Ptr{Uint8}, Cint, Ptr{Uint8}) libpq
    @c Ptr{FILE} tmpfile () libpq
    @c Ptr{Uint8} tmpnam (Ptr{Uint8},) libpq
    @c Ptr{Uint8} tmpnam_r (Ptr{Uint8},) libpq
    @c Ptr{Uint8} tempnam (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Cint fclose (Ptr{FILE},) libpq
    @c Cint fflush (Ptr{FILE},) libpq
    @c Cint fflush_unlocked (Ptr{FILE},) libpq
    @c Ptr{FILE} fopen (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Ptr{FILE} freopen (Ptr{Uint8}, Ptr{Uint8}, Ptr{FILE}) libpq
    @c Ptr{FILE} fdopen (Cint, Ptr{Uint8}) libpq
    @c Ptr{FILE} fmemopen (Ptr{None}, Cint, Ptr{Uint8}) libpq
    @c Ptr{FILE} open_memstream (Ptr{Ptr{Uint8}}, Ptr{Cint}) libpq
    @c None setbuf (Ptr{FILE}, Ptr{Uint8}) libpq
    @c Cint setvbuf (Ptr{FILE}, Ptr{Uint8}, Cint, Cint) libpq
    @c None setbuffer (Ptr{FILE}, Ptr{Uint8}, Cint) libpq
    @c None setlinebuf (Ptr{FILE},) libpq
    @c Cint fprintf (Ptr{FILE}, Ptr{Uint8}) libpq
    @c Cint printf (Ptr{Uint8},) libpq
    @c Cint sprintf (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Cint vdprintf (Cint, Ptr{Uint8}, Cint) libpq
    @c Cint dprintf (Cint, Ptr{Uint8}) libpq
    @c Cint fscanf (Ptr{FILE}, Ptr{Uint8}) libpq
    @c Cint scanf (Ptr{Uint8},) libpq
    @c Cint sscanf (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Cint fscanf (Ptr{FILE}, Ptr{Uint8}) libpq
    @c Cint scanf (Ptr{Uint8},) libpq
    @c Cint sscanf (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Cint fgetc (Ptr{FILE},) libpq
    @c Cint getc (Ptr{FILE},) libpq
    @c Cint getchar () libpq
    @c Cint getc_unlocked (Ptr{FILE},) libpq
    @c Cint getchar_unlocked () libpq
    @c Cint fgetc_unlocked (Ptr{FILE},) libpq
    @c Cint fputc (Cint, Ptr{FILE}) libpq
    @c Cint putc (Cint, Ptr{FILE}) libpq
    @c Cint putchar (Cint,) libpq
    @c Cint fputc_unlocked (Cint, Ptr{FILE}) libpq
    @c Cint putc_unlocked (Cint, Ptr{FILE}) libpq
    @c Cint putchar_unlocked (Cint,) libpq
    @c Cint getw (Ptr{FILE},) libpq
    @c Cint putw (Cint, Ptr{FILE}) libpq
    @c Ptr{Uint8} fgets (Ptr{Uint8}, Cint, Ptr{FILE}) libpq
    @c Ptr{Uint8} gets (Ptr{Uint8},) libpq
    # @c __ssize_t getdelim (Ptr{Ptr{Uint8}}, Ptr{Cint}, Cint, Ptr{FILE}) libpq
    # @c __ssize_t getline (Ptr{Ptr{Uint8}}, Ptr{Cint}, Ptr{FILE}) libpq
    @c Cint fputs (Ptr{Uint8}, Ptr{FILE}) libpq
    @c Cint puts (Ptr{Uint8},) libpq
    @c Cint ungetc (Cint, Ptr{FILE}) libpq
    @c Cint fread (Ptr{None}, Cint, Cint, Ptr{FILE}) libpq
    @c Cint fwrite (Ptr{None}, Cint, Cint, Ptr{FILE}) libpq
    @c Cint fread_unlocked (Ptr{None}, Cint, Cint, Ptr{FILE}) libpq
    @c Cint fwrite_unlocked (Ptr{None}, Cint, Cint, Ptr{FILE}) libpq
    @c Cint fseek (Ptr{FILE}, Clong, Cint) libpq
    @c Clong ftell (Ptr{FILE},) libpq
    @c None rewind (Ptr{FILE},) libpq
    # @c Cint fseeko (Ptr{FILE}, __off_t, Cint) libpq
    # @c __off_t ftello (Ptr{FILE},) libpq
    # @c Cint fgetpos (Ptr{FILE}, Ptr{fpos_t}) libpq
    # @c Cint fsetpos (Ptr{FILE}, Ptr{fpos_t}) libpq
    @c None clearerr (Ptr{FILE},) libpq
    @c Cint feof (Ptr{FILE},) libpq
    @c Cint ferror (Ptr{FILE},) libpq
    @c None clearerr_unlocked (Ptr{FILE},) libpq
    @c Cint feof_unlocked (Ptr{FILE},) libpq
    @c Cint ferror_unlocked (Ptr{FILE},) libpq
    @c None perror (Ptr{Uint8},) libpq
    @c Cint fileno (Ptr{FILE},) libpq
    @c Cint fileno_unlocked (Ptr{FILE},) libpq
    @c Ptr{FILE} popen (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Cint pclose (Ptr{FILE},) libpq
    @c Ptr{Uint8} ctermid (Ptr{Uint8},) libpq
    @c None flockfile (Ptr{FILE},) libpq
    @c Cint ftrylockfile (Ptr{FILE},) libpq
    @c None funlockfile (Ptr{FILE},) libpq
    @c Ptr{PGconn} PQconnectStart (Ptr{Uint8},) libpq
    @c Ptr{PGconn} PQconnectStartParams (Ptr{Ptr{Uint8}}, Ptr{Ptr{Uint8}}, Cint) libpq
    @c PostgresPollingStatusType PQconnectPoll (Ptr{PGconn},) libpq
    # @c Ptr{PGconn} PQconnectdb (Ptr{Uint8},) libpq
    @c Ptr{PGconn} PQconnectdb (Ptr{Uint8},) libpq
    @c Ptr{PGconn} PQconnectdbParams (Ptr{Ptr{Uint8}}, Ptr{Ptr{Uint8}}, Cint) libpq
    @c Ptr{PGconn} PQsetdbLogin (Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}) libpq
    @c None PQfinish (Ptr{PGconn},) libpq
    @c Ptr{PQconninfoOption} PQconndefaults () libpq
    @c Ptr{PQconninfoOption} PQconninfoParse (Ptr{Uint8}, Ptr{Ptr{Uint8}}) libpq
    @c None PQconninfoFree (Ptr{PQconninfoOption},) libpq
    @c Cint PQresetStart (Ptr{PGconn},) libpq
    @c PostgresPollingStatusType PQresetPoll (Ptr{PGconn},) libpq
    @c None PQreset (Ptr{PGconn},) libpq
    @c Ptr{PGcancel} PQgetCancel (Ptr{PGconn},) libpq
    @c None PQfreeCancel (Ptr{PGcancel},) libpq
    @c Cint PQcancel (Ptr{PGcancel}, Ptr{Uint8}, Cint) libpq
    @c Cint PQrequestCancel (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQdb (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQuser (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQpass (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQhost (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQport (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQtty (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQoptions (Ptr{PGconn},) libpq
    @c ConnStatusType PQstatus (Ptr{PGconn},) libpq
    @c PGTransactionStatusType PQtransactionStatus (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQparameterStatus (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Cint PQprotocolVersion (Ptr{PGconn},) libpq
    @c Cint PQserverVersion (Ptr{PGconn},) libpq
    @c Ptr{Uint8} PQerrorMessage (Ptr{PGconn},) libpq
    @c Cint PQsocket (Ptr{PGconn},) libpq
    @c Cint PQbackendPID (Ptr{PGconn},) libpq
    @c Cint PQconnectionNeedsPassword (Ptr{PGconn},) libpq
    @c Cint PQconnectionUsedPassword (Ptr{PGconn},) libpq
    @c Cint PQclientEncoding (Ptr{PGconn},) libpq
    @c Cint PQsetClientEncoding (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Ptr{None} PQgetssl (Ptr{PGconn},) libpq
    @c None PQinitSSL (Cint,) libpq
    @c None PQinitOpenSSL (Cint, Cint) libpq
    @c PGVerbosity PQsetErrorVerbosity (Ptr{PGconn}, PGVerbosity) libpq
    @c None PQtrace (Ptr{PGconn}, Ptr{FILE}) libpq
    @c None PQuntrace (Ptr{PGconn},) libpq
    @c PQnoticeReceiver PQsetNoticeReceiver (Ptr{PGconn}, PQnoticeReceiver, Ptr{None}) libpq
    @c PQnoticeProcessor PQsetNoticeProcessor (Ptr{PGconn}, PQnoticeProcessor, Ptr{None}) libpq
    @c pgthreadlock_t PQregisterThreadLock (pgthreadlock_t,) libpq
    @c Ptr{PGresult} PQexec (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Ptr{PGresult} PQexecParams (Ptr{PGconn}, Ptr{Uint8}, Cint, Ptr{Oid}, Ptr{Ptr{Uint8}}, Ptr{Cint}, Ptr{Cint}, Cint) libpq
    @c Ptr{PGresult} PQprepare (Ptr{PGconn}, Ptr{Uint8}, Ptr{Uint8}, Cint, Ptr{Oid}) libpq
    @c Ptr{PGresult} PQexecPrepared (Ptr{PGconn}, Ptr{Uint8}, Cint, Ptr{Ptr{Uint8}}, Ptr{Cint}, Ptr{Cint}, Cint) libpq
    @c Cint PQsendQuery (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Cint PQsendQueryParams (Ptr{PGconn}, Ptr{Uint8}, Cint, Ptr{Oid}, Ptr{Ptr{Uint8}}, Ptr{Cint}, Ptr{Cint}, Cint) libpq
    @c Cint PQsendPrepare (Ptr{PGconn}, Ptr{Uint8}, Ptr{Uint8}, Cint, Ptr{Oid}) libpq
    @c Cint PQsendQueryPrepared (Ptr{PGconn}, Ptr{Uint8}, Cint, Ptr{Ptr{Uint8}}, Ptr{Cint}, Ptr{Cint}, Cint) libpq
    @c Cint PQsetSingleRowMode (Ptr{PGconn},) libpq
    @c Ptr{PGresult} PQgetResult (Ptr{PGconn},) libpq
    @c Cint PQisBusy (Ptr{PGconn},) libpq
    @c Cint PQconsumeInput (Ptr{PGconn},) libpq
    @c Ptr{PGnotify} PQnotifies (Ptr{PGconn},) libpq
    @c Cint PQputCopyData (Ptr{PGconn}, Ptr{Uint8}, Cint) libpq
    @c Cint PQputCopyEnd (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Cint PQgetCopyData (Ptr{PGconn}, Ptr{Ptr{Uint8}}, Cint) libpq
    @c Cint PQgetline (Ptr{PGconn}, Ptr{Uint8}, Cint) libpq
    @c Cint PQputline (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Cint PQgetlineAsync (Ptr{PGconn}, Ptr{Uint8}, Cint) libpq
    @c Cint PQputnbytes (Ptr{PGconn}, Ptr{Uint8}, Cint) libpq
    @c Cint PQendcopy (Ptr{PGconn},) libpq
    @c Cint PQsetnonblocking (Ptr{PGconn}, Cint) libpq
    @c Cint PQisnonblocking (Ptr{PGconn},) libpq
    @c Cint PQisthreadsafe () libpq
    @c PGPing PQping (Ptr{Uint8},) libpq
    @c PGPing PQpingParams (Ptr{Ptr{Uint8}}, Ptr{Ptr{Uint8}}, Cint) libpq
    @c Cint PQflush (Ptr{PGconn},) libpq
    @c Ptr{PGresult} PQfn (Ptr{PGconn}, Cint, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{PQArgBlock}, Cint) libpq
    @c ExecStatusType PQresultStatus (Ptr{PGresult},) libpq
    @c Ptr{Uint8} PQresStatus (ExecStatusType,) libpq
    @c Ptr{Uint8} PQresultErrorMessage (Ptr{PGresult},) libpq
    @c Ptr{Uint8} PQresultErrorField (Ptr{PGresult}, Cint) libpq
    @c Cint PQntuples (Ptr{PGresult},) libpq
    @c Cint PQnfields (Ptr{PGresult},) libpq
    @c Cint PQbinaryTuples (Ptr{PGresult},) libpq
    @c Ptr{Uint8} PQfname (Ptr{PGresult}, Cint) libpq
    @c Cint PQfnumber (Ptr{PGresult}, Ptr{Uint8}) libpq
    @c Oid PQftable (Ptr{PGresult}, Cint) libpq
    @c Cint PQftablecol (Ptr{PGresult}, Cint) libpq
    @c Cint PQfformat (Ptr{PGresult}, Cint) libpq
    @c Oid PQftype (Ptr{PGresult}, Cint) libpq
    @c Cint PQfsize (Ptr{PGresult}, Cint) libpq
    @c Cint PQfmod (Ptr{PGresult}, Cint) libpq
    @c Ptr{Uint8} PQcmdStatus (Ptr{PGresult},) libpq
    @c Ptr{Uint8} PQoidStatus (Ptr{PGresult},) libpq
    @c Oid PQoidValue (Ptr{PGresult},) libpq
    @c Ptr{Uint8} PQcmdTuples (Ptr{PGresult},) libpq
    @c Ptr{Uint8} PQgetvalue (Ptr{PGresult}, Cint, Cint) libpq
    @c Cint PQgetlength (Ptr{PGresult}, Cint, Cint) libpq
    @c Cint PQgetisnull (Ptr{PGresult}, Cint, Cint) libpq
    @c Cint PQnparams (Ptr{PGresult},) libpq
    @c Oid PQparamtype (Ptr{PGresult}, Cint) libpq
    @c Ptr{PGresult} PQdescribePrepared (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Ptr{PGresult} PQdescribePortal (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Cint PQsendDescribePrepared (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Cint PQsendDescribePortal (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c None PQclear (Ptr{PGresult},) libpq
    @c None PQfreemem (Ptr{None},) libpq
    @c Ptr{PGresult} PQmakeEmptyPGresult (Ptr{PGconn}, ExecStatusType) libpq
    @c Ptr{PGresult} PQcopyResult (Ptr{PGresult}, Cint) libpq
    @c Cint PQsetResultAttrs (Ptr{PGresult}, Cint, Ptr{PGresAttDesc}) libpq
    @c Ptr{None} PQresultAlloc (Ptr{PGresult}, Cint) libpq
    @c Cint PQsetvalue (Ptr{PGresult}, Cint, Cint, Ptr{Uint8}, Cint) libpq
    @c Cint PQescapeStringConn (Ptr{PGconn}, Ptr{Uint8}, Ptr{Uint8}, Cint, Ptr{Cint}) libpq
    @c Ptr{Uint8} PQescapeLiteral (Ptr{PGconn}, Ptr{Uint8}, Cint) libpq
    @c Ptr{Uint8} PQescapeIdentifier (Ptr{PGconn}, Ptr{Uint8}, Cint) libpq
    @c Ptr{Cuchar} PQescapeByteaConn (Ptr{PGconn}, Ptr{Cuchar}, Cint, Ptr{Cint}) libpq
    @c Ptr{Cuchar} PQunescapeBytea (Ptr{Cuchar}, Ptr{Cint}) libpq
    @c Cint PQescapeString (Ptr{Uint8}, Ptr{Uint8}, Cint) libpq
    @c Ptr{Cuchar} PQescapeBytea (Ptr{Cuchar}, Cint, Ptr{Cint}) libpq
    @c None PQprint (Ptr{FILE}, Ptr{PGresult}, Ptr{PQprintOpt}) libpq
    @c None PQdisplayTuples (Ptr{PGresult}, Ptr{FILE}, Cint, Ptr{Uint8}, Cint, Cint) libpq
    @c None PQprintTuples (Ptr{PGresult}, Ptr{FILE}, Cint, Cint, Cint) libpq
    @c Cint lo_open (Ptr{PGconn}, Oid, Cint) libpq
    @c Cint lo_close (Ptr{PGconn}, Cint) libpq
    @c Cint lo_read (Ptr{PGconn}, Cint, Ptr{Uint8}, Cint) libpq
    @c Cint lo_write (Ptr{PGconn}, Cint, Ptr{Uint8}, Cint) libpq
    @c Cint lo_lseek (Ptr{PGconn}, Cint, Cint, Cint) libpq
    @c Oid lo_creat (Ptr{PGconn}, Cint) libpq
    @c Oid lo_create (Ptr{PGconn}, Oid) libpq
    @c Cint lo_tell (Ptr{PGconn}, Cint) libpq
    @c Cint lo_truncate (Ptr{PGconn}, Cint, Cint) libpq
    @c Cint lo_unlink (Ptr{PGconn}, Oid) libpq
    @c Oid lo_import (Ptr{PGconn}, Ptr{Uint8}) libpq
    @c Oid lo_import_with_oid (Ptr{PGconn}, Ptr{Uint8}, Oid) libpq
    @c Cint lo_export (Ptr{PGconn}, Oid, Ptr{Uint8}) libpq
    @c Cint PQlibVersion () libpq
    @c Cint PQmblen (Ptr{Uint8}, Cint) libpq
    @c Cint PQdsplen (Ptr{Uint8}, Cint) libpq
    @c Cint PQenv2encoding () libpq
    @c Ptr{Uint8} PQencryptPassword (Ptr{Uint8}, Ptr{Uint8}) libpq
    @c Cint pg_char_to_encoding (Ptr{Uint8},) libpq
    @c Ptr{Uint8} pg_encoding_to_char (Cint,) libpq
    @c Cint pg_valid_server_encoding_id (Cint,) libpq
end
