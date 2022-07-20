//
//  log.h
//  Medinology
//
//  Created by 양현서 on 2022/07/20.
//

#ifndef log_h
#define log_h

void debug(const char *message, ...) __attribute__((format(printf, 1, 2)));

#endif /* log_h */
