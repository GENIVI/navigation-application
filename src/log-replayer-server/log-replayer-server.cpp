#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <memory.h>

#include "log.h"

DLT_DECLARE_CONTEXT(gCtxENGI);

#define MSGIDLEN 20
#define BUFLEN 256
#define PORT1 9930   //port used for GNSS data
#define PORT2 9931   //port used for sensor data
#define PORT3 9932   //port used for vehicle data
#define IPADDR_DEFAULT "127.0.0.1"
#define MAXDELTA 1000  //max value to avoid overflow
#define MINLINESIZE 3
#define STRINGIFY2( x) #x
#define STRINGIFY(x) STRINGIFY2(x)

bool running = true;

void sighandler(int sig)
{
  running = false;
}

bool getStrToSend(FILE* file, char* line, int dim)
{
    static long unsigned int lastTimestamp = 0;
    long unsigned int timestamp = 0;
    long signed int delta = 0;

    if(dim <= 0)
    {
       return false;
    }

    char* ptrStr = fgets(line, dim, file);

    line[dim -1] = '\0';

    if(ptrStr == NULL || feof(file))
    {
        //error or end of file
        return false;
    }

    if(strchr(line, '#') != 0)
    {
        line[0] = '\0';
        return true; //skip comment line
    }

    if (!sscanf(line, "%lu", &timestamp))
    {
        line[0] = '\0';
        return true; //skip lines without timestamp
    }

    if(!lastTimestamp)
    {
        delta = 0;
    }
    else
    {
        delta = timestamp - lastTimestamp;
    }

    lastTimestamp = timestamp;

    if(delta < 0)
    {
        return true;
    }

    if(delta > MAXDELTA)
    {
        delta = MAXDELTA;
    }

    if(usleep(delta*1000) != 0) // TODO time drift issues
    {
        return true;
    }

    return true;
}


int main(int argc, char* argv[]) {
    DLT_REGISTER_APP("LRPS","LOG REPLAYER SERVER");
    DLT_REGISTER_CONTEXT(gCtxENGI,"ENGI","Engineering mode");

    struct sockaddr_in si_other;
    socklen_t slen = sizeof(si_other);
    int s;
    FILE * logfile = 0;
    char * filename = 0;
    char buf[BUFLEN];
    char msgId[MSGIDLEN];
    char * ipaddr = 0;

    signal(SIGTERM, sighandler);
    signal(SIGINT, sighandler);

    if(argc < 2)
    {
       return EXIT_FAILURE;
    }
    else
    {
        filename = argv[1];
        if(argc < 3)
            ipaddr = IPADDR_DEFAULT;
        else
            ipaddr = argv[2];
    }

    if((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
    {
        return EXIT_FAILURE;
    }

    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    //si_other.sin_port = htons(<port number>);
    if(inet_aton(ipaddr, &si_other.sin_addr) == 0)
    {
        return EXIT_FAILURE;
    }

    logfile = fopen(filename, "r");

    if(logfile == NULL)
    {
        return EXIT_FAILURE;
    }

    LOG_INFO_MSG(gCtxENGI,"Log replayer server started");

    while(running)
    {
        if(!getStrToSend(logfile,buf,BUFLEN))
        {
            //error or end of file
            return EXIT_FAILURE;
        }

        if (strlen(buf) < 3)
        {
            //skip empty lines (includes comments)
            continue;
        }

        sscanf(buf, "%*[^'$']$%[^',']", msgId);

        //GVGNS: list of supported message IDs
        //GVGNSPOS,GVGNSTIM
        if (strncmp ("GVGNS", msgId, strlen("GVGNS")) == 0)
        {
            si_other.sin_port = htons(PORT1);
            if(sendto(s, buf, strlen(buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
            {
                return EXIT_FAILURE;
            }
        }

        //GVSNS: list of supported message IDs
        //GVSNSVSP,GVSNSWHECNF,GVSNSWHE,GVSNSODO,GVSNSDRVDIR,GVSNSGYR,
        if(strncmp ("GVSNS", msgId, strlen("GVSNS")) == 0)
        {
            si_other.sin_port = htons(PORT2);
            if(sendto(s, buf, strlen(buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
            {
                return EXIT_FAILURE;
            }
        }
        //GVVEH: list of supported message IDs
        //GVVEHVER,GVVEHENGSPEED,GVVEHFUELLEVEL,GVVEHFUELCONS,GVVEHTOTALODO;
        if(strncmp ("GVVEH", msgId, strlen("GVVEH")) == 0)
        {
            si_other.sin_port = htons(PORT3);
            if(sendto(s, buf, strlen(buf)+1, 0, (struct sockaddr *)&si_other, slen) == -1)
            {
                return EXIT_FAILURE;
            }
        }
    }

    close(s);

    LOG_INFO_MSG(gCtxENGI,"Log replayer server stopped");

    return EXIT_SUCCESS;
}
