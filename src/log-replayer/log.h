/* Todo: Use DLT */

#define LOG_DEBUG_MSG(ctx,...) { fprintf(stderr,__VA_ARGS__) ; fprintf(stderr,"\n"); }
#define LOG_DEBUG(ctx,...) { fprintf(stderr,__VA_ARGS__) ; fprintf(stderr,"\n"); }
#define LOG_INFO_MSG(ctx,...) { fprintf(stderr,__VA_ARGS__) ; fprintf(stderr,"\n"); }
#define LOG_INFO(ctx,...) { fprintf(stderr,__VA_ARGS__) ; fprintf(stderr,"\n"); }
#define LOG_ERROR_MSG(ctx,...) { fprintf(stderr,__VA_ARGS__) ; fprintf(stderr,"\n"); }
#define LOG_ERROR(ctx,...) { fprintf(stderr,__VA_ARGS__) ; fprintf(stderr,"\n"); }
#define DLT_REGISTER_APP(x,y)
#define DLT_REGISTER_CONTEXT(x,y,z)
#define DLT_DECLARE_CONTEXT(x) void *x
