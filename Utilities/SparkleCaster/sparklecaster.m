#import <getopt.h>
#import <Foundation/Foundation.h>
#import "CasterModel.h"

int version = 0;
int help = 0;
int create = 0;
int output = 0;			char *outputpath = NULL;
int product = 0;		char *productstr = NULL;
int page = 0;			char *pagestr = NULL;
int description = 0;	char *descriptionstr = NULL;
int update = 0;
int castdoc = 0;		char *castdocpath = NULL;
int add = 0;
int enclosure = 0;		char *enclosurepath = NULL;
int appvers = 0;		char *appversstr = NULL;
int notes = 0;			char *notesstr = NULL;
int notefile = 0;		char *notefilepath = NULL;
int embed = 0;
int date = 0;			char *datestr = NULL;
int removevers = 0;
int appcast = 0;

struct option longopts[] =
{
	{"version", no_argument, NULL, 'v'},
	{"help", no_argument, NULL, 'h'},
	{"create", no_argument, NULL, 'c'},
	{"output", required_argument, NULL, 'o'},
	{"product", required_argument, NULL, 'p'},
	{"page", required_argument, NULL, 'g'},
	{"description", required_argument, NULL, 'r'},
	{"update", no_argument, NULL, 'u'},
	{"castdoc", required_argument, NULL, 't'},
	{"add", no_argument, NULL, 'a'},
	{"enclosure", required_argument, NULL, 'e'},
	{"appvers", required_argument, NULL, 's'},
	{"notes", required_argument, NULL, 'n'},
	{"notefile", required_argument, NULL, 'f'},
	{"embed", no_argument, NULL, 'b'},
	{"date", required_argument, NULL, 'd'},
	{"remove", no_argument, NULL, 'm'},
	{"appcast", no_argument, NULL, 'x'},
	{NULL, 0, NULL, 0}
};

static void showVersion(void)
{
	printf("sparklecaster v1.0\n");
	printf("Copyright (c) 2007\n");
}

static void showTryHelp(void)
{
	printf("For help:  sparklecaster --help\n");
}

static void usage(void)
{
	showVersion();
	
	printf("\n");
	printf(" -v --version                   show sparklecaster version\n");
	printf(" -h --help                      show sparklecaster usage information\n\n");
	
	printf(" -c --create                    create a new sparkle caster document\n");
	printf(" -o --output path               path to write the new sparkle caster document\n\n");
	printf(" -p --product product_name      (optional) set the product name\n");
	printf(" -g --page product_page         (optional) set the product home url\n");
	printf(" -r --description description   (optional) set the product description\n\n");
	
	printf(" -u --update                    update an existing sparkle caster document\n");
	printf(" -t --castdoc path              path to an existing sparkle caster document\n");
	printf(" -p --product product_name      (optional) set the product name\n");
	printf(" -g --page product_page         (optional) set the product home url\n");
	printf(" -r --description description   (optional) set the product description\n\n");
	
	printf(" -a --add                       add a version to an existing sparkle caster document\n");
	printf(" -t --castdoc path              path to an existing sparkle caster document\n");
	printf(" -e --enclosure path            path to the enclosure\n");
	printf(" -s --appvers version           version of the application\n");
	printf(" -n --notes notes               (optional: takes precedence over --notefile) set the release notes text\n");
	printf(" -f --notefile path             (optional) path to the release notes text\n");
	printf(" -b --embed                     (optional) embed the release notes in the appcast\n");
	printf(" -d --date date                 (optional) release date of the version\n\n");
	
	printf(" -m --remove                    remove a version from an existing sparkle caster document\n");
	printf(" -t --castdoc path              path to an existing sparkle caster document\n");
	printf(" -s --appvers version           version of the application\n\n");
	
	printf(" -x --appcast                   create an appcast from a sparkle caster document\n");
	printf(" -t --castdoc path              path to an existing sparkle caster document\n");
	printf(" -o --output path               path to write the appcast xml file\n");
}

static int validateOpts(void)
{
	int error = 1;
	
	if (!create && !update && !add && !appcast && !version && !help)
		printf ("--create or --update or --add or --appcast must be specified\n");
	else if (create && !outputpath)
		printf ("--create requires the --output option\n");
	else if (update && !castdocpath)
		printf ("--update requires the --castdoc option\n");
	else if (add && !castdocpath)
		printf ("--add requires the --castdoc option\n");
	else if (add && !enclosurepath)
		printf ("--add requires the --enclosure option\n");
	else if (add && !appvers)
		printf ("--add requires the --appvers option\n");
	else if (removevers && !castdoc)
		printf ("--remove requires the --castdoc option\n");
	else if (removevers && !appvers)
		printf ("--remove requires the --appvers option\n");
	else if (appcast && !castdoc)
		printf ("--appcast requires the --castdoc option\n");
	else if (appcast && !output)
		printf ("--appcast requires the --output option\n");
	else
		error = 0;
	
	if (error)
		showTryHelp();
	
	return error;
}

static void createCasterDoc(void)
{
	CasterModel *caster = [[[CasterModel alloc] init] autorelease];
	
	if (productstr)
		[caster setProductName:[NSString stringWithCString:productstr]];
	
	if (pagestr)
		[caster setProductPage:[NSString stringWithCString:pagestr]];
	
	if (descriptionstr)
		[caster setProductDescription:[NSString stringWithCString:descriptionstr]];
	
	NSData *data = [caster data];
	if (![data writeToFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:outputpath length:strlen(outputpath)] atomically:YES])
		printf("*** error: cannot write to file: %s\n", outputpath);
}

static void updateCasterDoc(void)
{
	NSData *data = [NSData dataWithContentsOfFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:castdocpath length:strlen(castdocpath)]];
	
	if (!data)
		printf("*** error: cannot read from file: %s\n", castdocpath);
	else
	{
		CasterModel *caster = [[[CasterModel alloc] initWithData:data] autorelease];
		
		if (productstr)
			[caster setProductName:[NSString stringWithCString:productstr]];
		
		if (pagestr)
			[caster setProductPage:[NSString stringWithCString:pagestr]];
		
		if (descriptionstr)
			[caster setProductDescription:[NSString stringWithCString:descriptionstr]];
		
		NSData *data = [caster data];
		if (![data writeToFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:castdocpath length:strlen(castdocpath)] atomically:YES])
			printf("*** error: cannot write to file: %s\n", castdocpath);
	}
}

static void addToCasterDoc(void)
{
	NSData *data = [NSData dataWithContentsOfFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:castdocpath length:strlen(castdocpath)]];
	
	if (!data)
		printf("*** error: cannot read from file: %s\n", castdoc);
	else
	{
		CasterModel *caster = [[[CasterModel alloc] initWithData:data] autorelease];
		
		[caster addEnclosure:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:enclosurepath length:strlen(enclosurepath)] withVersion:[NSString stringWithCString:appversstr]];
		
		NSData *data = [caster data];
		if (![data writeToFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:castdocpath length:strlen(castdocpath)] atomically:YES])
			printf("*** error: cannot write to file: %s\n", castdocpath);
	}
}

static void removeFromCasterDoc(void)
{
	NSData *data = [NSData dataWithContentsOfFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:castdocpath length:strlen(castdocpath)]];
	
	if (!data)
		printf("*** error: cannot read from file: %s\n", castdoc);
	else
	{
		CasterModel *caster = [[[CasterModel alloc] initWithData:data] autorelease];
		
		[caster removeVersion:[NSString stringWithCString:appversstr]];
		
		NSData *data = [caster data];
		if (![data writeToFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:castdocpath length:strlen(castdocpath)] atomically:YES])
			printf("*** error: cannot write to file: %s\n", castdocpath);
	}
}

static void createAppCast(void)
{
	NSData *data = [NSData dataWithContentsOfFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:castdocpath length:strlen(castdocpath)]];
	
	if (!data)
		printf("*** error: cannot read from file: %s\n", castdoc);
	else
	{
		CasterModel *caster = [[[CasterModel alloc] initWithData:data] autorelease];
		
		NSData *data = [caster appcastData];
		if (![data writeToFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:outputpath length:strlen(outputpath)] atomically:YES])
			printf("*** error: cannot write to file: %s\n", outputpath);
	}
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int error = 0;
	
	int opt;
	while ((opt = getopt_long(argc, (char * const *) argv, "vhco:p:g:r:ut:ae:s:n:f:bd:mx", longopts, NULL)) != -1)
	{
		switch (opt)
		{
			case 'v':
				version = 1;
				break;
			case 'h':
				help = 1;
				break;
			case 'c':
				create = 1;
				break;
			case 'o':
				output = 1;
				outputpath = optarg;
				break;
			case 'p':
				product = 1;
				productstr = optarg;
				break;
			case 'g':
				page = 1;
				pagestr = optarg;
				break;
			case 'r':
				description = 1;
				descriptionstr = optarg;
				break;
			case 'u':
				update = 1;
				break;
			case 't':
				castdoc = 1;
				castdocpath = optarg;
				break;
			case 'a':
				add = 1;
				break;
			case 'e':
				enclosure = 1;
				enclosurepath = optarg;
				break;
			case 's':
				appvers = 1;
				appversstr = optarg;
				break;
			case 'n':
				notes = 1;
				notesstr = optarg;
				break;
			case 'f':
				notefile = 1;
				notefilepath = optarg;
				break;
			case 'b':
				embed = 1;
				break;
			case 'd':
				date = 1;
				datestr = optarg;
				break;
			case 'm':
				removevers = 1;
				break;
			case 'x':
				appcast = 1;
				break;
			case '?':
				/* getopt_long already issued an error message */
				showTryHelp();
				error = 1;
				break;
			default:
				help = 1;
				break;
		}
	}
	
	argc -= optind;
	argv += optind;
	
	if (version && !help)
		showVersion();
	
	if (help)
		usage();
	
	if (!error)
		error = validateOpts();
	
	if (!error)
	{
		if (create)
			createCasterDoc();
		else if (update)
			updateCasterDoc();
		else if (add)
			addToCasterDoc();
		else if (removevers)
			removeFromCasterDoc();
		else if (appcast)
			createAppCast();
	}
	
	[pool release];
	
	return EXIT_SUCCESS;
}
