#ifndef __REGEX_H__
#define __REGEX_H__

#include <stdio.h>
#include <string.h>
#include <regex.h>

//要使用linux c独有的正则表达式
static const int REG_SUBPATT_SIZE = 512;

class CRegExp {
	public:
		static CRegExp *Instance() {
			static CRegExp singleton;
			return &singleton;
		}

	private:
		CRegExp() {};

		bool regCompile(
				regex_t *regex
				, const char *pattern
				, bool no_sub
				, bool icase);

	public:
		bool isRegMatch(
				const char *src_str
				, const char *pattern
				, bool no_sub
				, bool icase);

		int getRegMatch(
				const char *src_str
				, const char *pattern
				, char buf[][REG_SUBPATT_SIZE]
				, int max_match_num
				, bool no_sub
				, bool icase);

		char *regReplace(
				char *src_str
				, const char *pattern
				, const char *replacement
				, bool no_sub
				, bool icase);

};

bool CRegExp::regCompile(
		regex_t *regex
		, const char *pattern
		, bool no_sub
		, bool icase) {
	int flags = REG_EXTENDED;
	/* If ignore case */
	flags |= icase ? REG_ICASE : 0;
	/* If return sub pattern */
	flags |= no_sub ? REG_NOSUB : 0;
	int ret_code = regcomp(regex, pattern, flags);
	if (ret_code  != 0) {        
		char str_err[256];
		regerror(ret_code, regex, str_err, sizeof(str_err));
		fprintf(stderr, "%s\n", str_err);
		return false;
	}
	return true;
}

bool CRegExp::isRegMatch(
		const char *src_str
		, const char *pattern
		, bool no_sub
		, bool icase) {
	regex_t regex;
	if (regCompile(&regex, pattern, no_sub, icase)) {
		if (regexec(&regex, src_str, 0, NULL, 0) == 0) {
			regfree(&regex);
			return true;
		}
		regfree(&regex);
	}
	return false;
}

int CRegExp::getRegMatch(
		const char *src_str
		, const char *pattern
		, char buf[][REG_SUBPATT_SIZE]
		, int max_match_num
		, bool no_sub
		, bool icase) {
	if (strchr(pattern, '(') == NULL) {
		return 0;
	}
	memset(buf, 0, sizeof(buf));
	regex_t regex;
	if (regCompile(&regex, pattern, no_sub, icase)) {
		/* regmatchs[0] store main pattern result.
		 * regmaths[1] store sub pattern result.
		 * only match one times.
		 */
		int match_num	= 0;
		const char *pos = src_str;
		regmatch_t regmatchs[2];
		memset(regmatchs, 0, sizeof(regmatchs));
		while(regexec(&regex, pos, 2, regmatchs, 0) == 0) {
			/* 
			 * regmatchs[1].rm_eo piont to the next pos of
			 * the end of match string
			 */
			int sub_len = regmatchs[1].rm_eo - regmatchs[1].rm_so;
			int max_sub_len = REG_SUBPATT_SIZE - 1;
			(sub_len > max_sub_len) ? (sub_len = max_sub_len) : 0;

			const char *sub_str = pos + regmatchs[1].rm_so;
			strncpy(buf[match_num++], sub_str, sub_len);
			pos += regmatchs[1].rm_eo;
			if (match_num >= max_match_num) {
				break;
			}
		}
		regfree(&regex);
		return match_num;
	}
	return 0;
}

char *CRegExp::regReplace(
		char *src_str
		, const char *pattern
		, const char *replacement
		, bool no_sub
		, bool icase) {
	if (NULL == src_str 
			|| NULL== replacement
			|| NULL == pattern) {
		return src_str;
	}
	regex_t regex;
	if (regCompile(&regex, pattern, no_sub, icase)) {
		char tmpbuf[1024];
		int src_str_len = strlen(src_str);
		if (src_str_len >= sizeof(tmpbuf)) {
			fprintf(stderr, "string out of range\n");
			return src_str;
		}
		char *pos = src_str;
		regmatch_t regmatchs[2];
		memset(regmatchs, 0, sizeof(regmatchs));
		while (regexec(&regex, pos, 2, regmatchs, 0) == 0) {
			char *begin	= pos + regmatchs[0].rm_so;
			char *end	=  pos + regmatchs[0].rm_eo;
			strcpy(tmpbuf, end);
			*begin = '\0';
			strcat(src_str, replacement);
			pos = src_str + strlen(src_str);
			strcat(src_str, tmpbuf);
			if (strlen(src_str) > src_str_len) {
				src_str[src_str_len] = '\0';
				fprintf(stderr, "string out of range\n");
				break;
			}
		}
		regfree(&regex);
	}
	return src_str;
}

#endif
