
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>

#include <unistd.h>
#include <sysexits.h>
#include <sys/socket.h>
#include <netinet/in.h>

/* --- */
#define DEFAULT_PORT    (6668)

/* --- 0 OK, -1 error */
int do_send(const char *localaddr, uint16_t port, const char *verb)
{
    int len, rc, fd;
    struct sockaddr_in destaddr;
    int broadcast = 1;

    if (!verb || !(len=strlen(verb)))
        return -1;

    if ((rc=socket(AF_INET,SOCK_DGRAM,0))<0)
        return rc;
    fd = rc;

    if ((rc=setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast))))
        return rc;

    bzero(&destaddr,sizeof(destaddr));
    destaddr.sin_family = AF_INET;
    if (broadcast)
        destaddr.sin_addr.s_addr = INADDR_BROADCAST;
    else
        destaddr.sin_addr.s_addr = inet_addr(localaddr);
    destaddr.sin_port=htons(port);

    for(;;) {
        rc = sendto(fd, verb, len, 0, (struct sockaddr *)&destaddr, sizeof(destaddr));
        if (rc>=0/* we don't expect ==0 */) {
            return (rc==len)?0:-2;
            }
        /* else */
        switch(errno) {
            case EINTR:
                continue; /* restart */
            }
        return -1;
        }
}
        
/* --- */
int usage(retval)
{
#define MSG "brudps -v <verb> [-a <localaddr>] [-p <port>] [-h]\n"
    fprintf(retval?stderr:stdout, MSG);
    exit(retval);
    return retval;  /* should reached here */
}

/* --- */
int main(int argc, char**argv)
{
    int c;
    const char *localaddr = "127.0.0.1";
    const char *verb = NULL;
    int rc;
    int tmp;
    uint16_t port = DEFAULT_PORT;
    while((c=getopt(argc, argv, "a:hp:v:"))!=-1) {
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
            case 'v':
                verb = optarg;
                break;
            }
        }
    if (!localaddr || !verb) {
        return usage(EX_USAGE);
        }
    if ((tmp=do_send(localaddr, port, verb))) {
        fprintf(stderr, "Error (%d): [%d] %s\n", tmp, errno, strerror(errno)/*NB: not reentrant*/);    
        }
}

