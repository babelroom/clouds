
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <unistd.h>
#include <sysexits.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <limits.h>
#include <errno.h>

/* --- */
#define DEFAULT_PORT    (6668)

/* --- 1==match, 0==timeout, -1 system error: look in errno, other <0: other error --- */
int do_loop(const char *localaddr, uint16_t port, const char *verbs[], int timeout)
{
    int rc, fd;
    enum { BUF_SIZE=1024 };
    char buf[BUF_SIZE];
    struct sockaddr_in servaddr;
    int option = 1;

    if ((rc=socket(AF_INET,SOCK_DGRAM,0))<0)
        return rc;
    fd = rc;

    //if ((rc=setsockopt(fd, SOL_SOCKET, (SO_REUSEADDR | SO_REUSEPORT), &option, sizeof(option)))) ????
    if ((rc=setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &option, sizeof(option))))
        return rc;

    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr=htonl(INADDR_ANY);
    //servaddr.sin_addr.s_addr=inet_addr(localaddr);
    servaddr.sin_port=htons(port);
    if ((rc=bind(fd, (struct sockaddr *)&servaddr, sizeof(servaddr))))
        return rc;

    if (timeout>0) {
        struct timeval tv;
        tv.tv_sec = timeout;
        tv.tv_usec = 0;
        if ((rc=setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv))))
            return rc;
        }

    /* --- */
    for(;;) {
        int ret = recvfrom(fd, buf, BUF_SIZE-1, 0, NULL, NULL);
        if (ret==0)
            return -2;  /* unexpected in this case */
        if (ret>0) {
            int i;
            const char *verb;
            buf[ret] = '\0';
            for(i=0; (verb=verbs[i]); i++)
                if (!strcmp(verb,buf)) {  /* match! */
                    printf("[%s]\n",verb);
                    //return 1;
                    }
            }
        else {  /* <0 */
            switch(errno) {
                case EINTR: /* restart */   // TMP TMP TMP adjust for timeout .... TODO !! FIXME !!!!
                    continue;
                case ETIMEDOUT:
                    return 0;
                default:
                    return -1;
                }
            }
        }
}

/* --- */
int usage(retval)
{
#define MSG "brudpr -v <verb1[|verb2|...> [-a <localaddr>] [-t <timeout(seconds)>] [-p <port>] [-h]\n"
    fprintf(retval?stderr:stdout, MSG);
    exit(retval);
    return retval;  /* should reached here */
}

/* --- */
const char **make_verbs(const char *full_string)
{
    char *saveptr;
    char *str;
    int count = 1;
    char **result = NULL;
    if (!full_string)
        return NULL;
    result = (char **)malloc(sizeof(char*)*(count+1));
    *result = strdup(full_string);
    for((str=strtok_r(*result, "|", &saveptr));
        str!=NULL;
        (str=strtok_r(NULL, "|", &saveptr))) {
        result = realloc(result, sizeof(char*)*(count+2));
        result[count++] = str;
        }
    result[count] = NULL;
    return (const char **)result;
}

/* --- */
void free_verbs(const char **verbs)
{
    if (verbs) {
        free((char *)(verbs[0]));
        free(verbs);
        }
}

/* --- */
void print_verbs(FILE *out, const char **verbs) {
    const char *str;
    while((str=*(++verbs))) {
        fprintf(out, "[%s]\n", str);
        }
}

/* --- */
int main(int argc, char**argv)
{
    int c;
    const char *localaddr = "127.0.0.1";
    const char **verbs = NULL;
    const char **verbs2delete = NULL;
    int timeout = -1;   /* infinite */
    int rc;
    int tmp;
    uint16_t port = DEFAULT_PORT;
    while((c=getopt(argc, argv, "a:hp:t:v:"))!=-1) {
        switch(c) {
            case 'a':
                localaddr = optarg;
                break;
            case 'h':
                return usage(0);
            case 'p':
                if (!optarg)
                    return usage(EX_USAGE);
                tmp = atoi(optarg);
                if (tmp<1 || tmp>USHRT_MAX)
                    return usage(EX_USAGE);
                port = tmp;
                break;
            case 't':
                if (!optarg) 
                    return usage(EX_USAGE);
                timeout = atoi(optarg);
                break;
            case 'v':
                verbs2delete = make_verbs(optarg);
                verbs = &(verbs2delete[1]);
                break;
            }
        }
    if (!localaddr || !verbs || !timeout) {
        return usage(EX_USAGE);
        }
//    print_verbs(stdout, verbs);
    if ((rc = do_loop(localaddr, port, verbs, timeout)<0)) {
        fprintf(stderr, "Error (%d): [%d] %s\n", tmp, errno, strerror(errno)/*NB: not reentrant*/);    
        }
    if (verbs2delete)
        free_verbs(verbs2delete);
    return rc<0?-1:0;
}

