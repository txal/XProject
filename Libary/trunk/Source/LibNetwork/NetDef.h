#ifndef __NETDEF_H__
#define __NETDEF_H__

// Max service num 
#define MAX_SERVICE_NUM 127

// Session id mask(service << 24 | connection id) 
#define SESSION_MASK 0xFFFFFF




// 4M innernet max read/write buf size
#define INNERNET_MAX_RWBUF (4*1024*1024)

// Max read/write size in on event
#define INNERNET_MAX_RW_PEREVENT (4*1024*1024)




// Max read buf size 
#define EXTERNET_MAX_RECVBUF (32*1024)

// Max write buf size 
#define EXTERNET_MAX_SENDBUF (64*1024)

// Max read size one event 
#define EXTERNET_MAX_READ_PEREVENT (32*1024)

// Max write size one event 
#define EXTERNET_MAX_BLOCK_SIZE (64*1024*2)
#define EXTERNET_MAX_WRITE_PEREVENT (64*1024)

// Max recv packet in one minute 
#define EXTERNET_MAX_INPACKET_PERMIN 10800 //(60*60*3) 180 q/s

// Session dead timeout in second 
#define EXTERET_SESSION_DEAD_TIMEOUT 180

#endif