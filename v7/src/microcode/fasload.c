/* -*-C-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/microcode/fasload.c,v 9.64 1992/02/18 17:31:11 jinx Exp $

Copyright (c) 1987-1992 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case. */

/* The "fast loader" which reads in and relocates binary files and then
   interns symbols.  It is called with one argument: the (character
   string) name of a file to load.  It is called as a primitive, and
   returns a single object read in. */

#include "scheme.h"
#include "prims.h"
#include "osscheme.h"
#include "osfile.h"
#include "osio.h"
#include "gccode.h"
#include "trap.h"
#include "option.h"
#include "prmcon.h"

static Tchannel load_channel;

#define Load_Data(size, buffer)						\
  ((OS_channel_read_load_file						\
    (load_channel,							\
     ((char *) (buffer)),						\
     ((size) * (sizeof (SCHEME_OBJECT)))))				\
   / (sizeof (SCHEME_OBJECT)))

#include "load.c"

extern char * EXFUN (malloc, (int));

extern char * Error_Names [];
extern char * Abort_Names [];
extern SCHEME_OBJECT * load_renumber_table;
extern SCHEME_OBJECT compiler_utilities;

extern SCHEME_OBJECT EXFUN (intern_symbol, (SCHEME_OBJECT));
extern void EXFUN (install_primitive_table,
		   (SCHEME_OBJECT *, long, Boolean));
extern void EXFUN (compiler_reset_error, (void));
extern void EXFUN (compiler_initialize, (long));
extern void EXFUN (compiler_reset, (SCHEME_OBJECT));

static long failed_heap_length = -1;

#define MODE_BAND		0
#define MODE_CHANNEL		1
#define MODE_FNAME		2

static void
DEFUN (read_channel_continue, (header, mode, repeat_p),
       SCHEME_OBJECT * header AND int mode AND Boolean repeat_p)
{
  long value, heap_length;

  value = (initialize_variables_from_fasl_header (header));

  if (value != FASL_FILE_FINE)
  {
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);
    }
    switch (value)
    {
      /* These may want to be separated further. */
      case FASL_FILE_TOO_SHORT:
      case FASL_FILE_NOT_FASL:
      case FASL_FILE_BAD_MACHINE:
      case FASL_FILE_BAD_VERSION:
      case FASL_FILE_BAD_SUBVERSION:
        signal_error_from_primitive (ERR_FASL_FILE_BAD_DATA);
	/*NOTREACHED*/

      case FASL_FILE_BAD_PROCESSOR:
      case FASL_FILE_BAD_INTERFACE:
	signal_error_from_primitive (ERR_FASLOAD_COMPILED_MISMATCH);
	/*NOTREACHED*/
    }
  }

  if (Or2 (Reloc_Debug, File_Load_Debug))
  {
    print_fasl_information();
  }

  if (!(TEST_CONSTANT_TOP (Free_Constant + Const_Count)))
  {
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);
    }
    signal_error_from_primitive (ERR_FASL_FILE_TOO_BIG);
    /*NOTREACHED*/
  }

  heap_length = (Heap_Count + Primitive_Table_Size + Primitive_Table_Length);

  if (GC_Check (heap_length))
  {
    if (repeat_p ||
	(heap_length == failed_heap_length) ||
	(mode == MODE_BAND))
    {
      if (mode != MODE_CHANNEL)
      {
	OS_channel_close_noerror (load_channel);
      }
      signal_error_from_primitive (ERR_FASL_FILE_TOO_BIG);
      /*NOTREACHED*/
    }
    else if (mode == MODE_CHANNEL)
    {
      SCHEME_OBJECT reentry_record[1];

      /* IMPORTANT: This KNOWS that it was called from BINARY-FASLOAD.
	 If this is ever called from elsewhere with MODE_CHANNEL,
	 it will have to be parameterized better.

	 This reentry record must match the expectations of
	 continue_fasload below.
       */	 

      Request_GC (heap_length);

      /* This assumes that header == (Free + 1) */
      header = Free;
      Free += (FASL_HEADER_LENGTH + 1);
      *header = (MAKE_OBJECT (TC_MANIFEST_NM_VECTOR, FASL_HEADER_LENGTH));

      reentry_record[0] = (MAKE_POINTER_OBJECT (TC_NON_MARKED_VECTOR, header));
      
      suspend_primitive (CONT_FASLOAD,
			 ((sizeof (reentry_record)) /
			  (sizeof (SCHEME_OBJECT))),
			 &reentry_record[0]);
      immediate_interrupt ();
      /*NOTREACHED*/
    }
    else
    {
      failed_heap_length = heap_length;
      OS_channel_close_noerror (load_channel);
      Request_GC (heap_length);
      signal_interrupt_from_primitive ();
      /*NOTREACHED*/
    }
  }
  failed_heap_length = -1;

  if ((band_p) && (mode != MODE_BAND))
  {
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);      
    }
    signal_error_from_primitive (ERR_FASLOAD_BAND);
  }
  return;
}

static void
DEFUN (read_channel_start, (channel, mode), Tchannel channel AND int mode)
{
  load_channel = channel;

  if (GC_Check (FASL_HEADER_LENGTH + 1))
  {
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);
    }
    Request_GC (FASL_HEADER_LENGTH + 1);
    signal_interrupt_from_primitive ();
    /* NOTREACHED */
  }

  if (Load_Data (FASL_HEADER_LENGTH, ((char *) (Free + 1))) !=
      FASL_HEADER_LENGTH)
  {
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);
    }
    signal_error_from_primitive (ERR_FASL_FILE_BAD_DATA);
  }

  read_channel_continue ((Free + 1), mode, false);
  return;
}

static void
DEFUN (read_file_start, (file_name, from_band_load),
       CONST char * file_name AND Boolean from_band_load)
{
  Tchannel channel;

  channel = (OS_open_load_file (file_name));
  if (Per_File)
  {
    debug_edit_flags ();
  }
  if (channel == NO_CHANNEL)
  {
    error_bad_range_arg (1);
  }
  read_channel_start (channel,
		      (from_band_load ? MODE_BAND : MODE_FNAME));
  return;
}

static SCHEME_OBJECT *
DEFUN (read_file_end, (mode), int mode)
{
  SCHEME_OBJECT *table, *ignore;
  extern unsigned long checksum_area ();

  if ((Load_Data (Heap_Count, ((char *) Free))) != Heap_Count)
  {
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);
    }
    signal_error_from_primitive (ERR_IO_ERROR);
  }
  computed_checksum =
    (checksum_area (((unsigned long *) Free),
		    Heap_Count,
		    computed_checksum));
  NORMALIZE_REGION(((char *) Free), Heap_Count);
  Free += Heap_Count;

  if ((Load_Data (Const_Count, ((char *) Free_Constant))) != Const_Count)
  {
    SET_CONSTANT_TOP ();
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);
    }
    signal_error_from_primitive (ERR_IO_ERROR);
  }
  computed_checksum =
    (checksum_area (((unsigned long *) Free_Constant),
		    Const_Count,
		    computed_checksum));
  NORMALIZE_REGION (((char *) Free_Constant), Const_Count);
  Free_Constant += Const_Count;
  SET_CONSTANT_TOP ();

  table = Free;
  if ((Load_Data (Primitive_Table_Size, ((char *) Free))) !=
      Primitive_Table_Size)
  {
    if (mode != MODE_CHANNEL)
    {
      OS_channel_close_noerror (load_channel);
    }
    signal_error_from_primitive (ERR_IO_ERROR);
  }
  computed_checksum =
    (checksum_area (((unsigned long *) Free),
		    Primitive_Table_Size,
		    computed_checksum));
  NORMALIZE_REGION (((char *) table), Primitive_Table_Size);
  Free += Primitive_Table_Size;

  if (mode != MODE_CHANNEL)
  {
    OS_channel_close_noerror (load_channel);
  }

  if ((computed_checksum != ((unsigned long) 0)) &&
      (dumped_checksum != SHARP_F))
  {
    signal_error_from_primitive (ERR_IO_ERROR);
  }
  return (table);
}

/* Statics used by Relocate, below */

relocation_type
  heap_relocation,
  const_relocation,
  stack_relocation;

/* Relocate a pointer as read in from the file.  If the pointer used
   to point into the heap, relocate it into the heap.  If it used to
   be constant area, relocate it to constant area.  Otherwise give an
   error.
*/

#ifdef ENABLE_DEBUGGING_TOOLS

static Boolean Warned = false;

static SCHEME_OBJECT *
DEFUN (Relocate, (P), long P)
{
  SCHEME_OBJECT *Result;

  if ((P >= Heap_Base) && (P < Dumped_Heap_Top))
  {
    Result = ((SCHEME_OBJECT *) (P + heap_relocation));
  }
  else if ((P >= Const_Base) && (P < Dumped_Constant_Top))
  {
    Result = ((SCHEME_OBJECT *) (P + const_relocation));
  }
  else if ((P >= Dumped_Constant_Top) && (P < Dumped_Stack_Top))
  {
    Result = ((SCHEME_OBJECT *) (P + stack_relocation));
  }
  else
  {
    printf ("Pointer out of range: 0x%lx\n", P);
    if (!Warned)
    {
      printf ("Heap: %lx-%lx, Constant: %lx-%lx, Stack: ?-0x%lx\n",
	      ((long) Heap_Base), ((long) Dumped_Heap_Top),
	      ((long) Const_Base), ((long) Dumped_Constant_Top),
	      ((long) Dumped_Stack_Top));
      Warned = true;
    }
    Result = ((SCHEME_OBJECT *) 0);
  }
  if (Reloc_Debug)
  {
    printf ("0x%06lx -> 0x%06lx\n", P, ((long) Result));
  }
  return (Result);
}

#define Relocate_Into(Loc, P) (Loc) = Relocate(P)

#else /* not ENABLE_DEBUGGING_TOOLS */

#define Relocate_Into(Loc, P)						\
{									\
  if ((P) < Dumped_Heap_Top)						\
  {									\
    (Loc) = ((SCHEME_OBJECT *) ((P) + heap_relocation));		\
  }									\
  else if ((P) < Dumped_Constant_Top)					\
  {									\
    (Loc) = ((SCHEME_OBJECT *) ((P) + const_relocation));		\
  }									\
  else									\
  {									\
    (Loc) = ((SCHEME_OBJECT *) ((P) + stack_relocation));		\
  }									\
}

#ifndef Conditional_Bug

#define Relocate(P)							\
((P < Const_Base) ?							\
 ((SCHEME_OBJECT *) (P + heap_relocation)) :				\
 ((P < Dumped_Constant_Top) ?						\
  ((SCHEME_OBJECT *) (P + const_relocation)) :				\
  ((SCHEME_OBJECT *) (P + stack_relocation))))

#else /* Conditional_Bug */

static SCHEME_OBJECT *Relocate_Temp;

#define Relocate(P)							\
  (Relocate_Into(Relocate_Temp, P), Relocate_Temp)

#endif /* Conditional_Bug */
#endif /* ENABLE_DEBUGGING_TOOLS */

/* Next_Pointer starts by pointing to the beginning of the block of
   memory to be handled.  This loop relocates all pointers in the
   block of memory.
*/

static void
DEFUN (Relocate_Block, (Scan, Stop_At),
       fast SCHEME_OBJECT * Scan AND fast SCHEME_OBJECT * Stop_At)
{
  fast long address;
  fast SCHEME_OBJECT Temp;

  if (Reloc_Debug)
  {
    fprintf (stderr,
	     "\nRelocate_Block: block = 0x%lx, length = 0x%lx, end = 0x%lx.\n",
	     ((long) Scan), ((long) ((Stop_At - Scan) - 1)), ((long) Stop_At));
  }

  while (Scan < Stop_At)
  {
    Temp = *Scan;
    Switch_by_GC_Type (Temp)
    {
      case TC_BROKEN_HEART:
      case TC_MANIFEST_SPECIAL_NM_VECTOR:
      case_Fasload_Non_Pointer:
        Scan += 1;
	break;

      case TC_PRIMITIVE:
	*Scan++ = (load_renumber_table [PRIMITIVE_NUMBER (Temp)]);
	break;

      case TC_PCOMB0:
	*Scan++ =
	  OBJECT_NEW_TYPE
	    (TC_PCOMB0, (load_renumber_table [PRIMITIVE_NUMBER (Temp)]));
        break;

      case TC_MANIFEST_NM_VECTOR:
        Scan += (OBJECT_DATUM (Temp) + 1);
        break;

      case TC_LINKAGE_SECTION:
      {
	/* Important: The relocation below will not work on machines
	   where Heap_In_Low_Memory is not true.  At this point we
	   don't have the original Memory_Base to find the original
	   address.  Perhaps it should be dumped.
	   This also applies to TC_MANIFEST_CLOSURE.
	   The lines affected are the ones where ADDRESS_TO_DATUM is used.
	 */
	switch (READ_LINKAGE_KIND(Temp))
	{
	  case REFERENCE_LINKAGE_KIND:
	  case ASSIGNMENT_LINKAGE_KIND:
	  {
	    /* Assumes that all others are objects of type TC_QUAD without
	       their type codes.
	       */

	    fast long count;

	    Scan++;
	    for (count = (READ_CACHE_LINKAGE_COUNT (Temp));
		 --count >= 0;
		 )
	    {
	      address = (ADDRESS_TO_DATUM ((SCHEME_OBJECT *) (*Scan)));
	      *Scan++ = ((SCHEME_OBJECT) (Relocate (address)));
	    }
	    break;
	  }

	  case OPERATOR_LINKAGE_KIND:
	  case GLOBAL_OPERATOR_LINKAGE_KIND:
	  {
	    fast long count;
	    fast char *word_ptr;
	    SCHEME_OBJECT *end_scan;

	    START_OPERATOR_RELOCATION (Scan);
	    count = (READ_OPERATOR_LINKAGE_COUNT (Temp));
	    word_ptr = (FIRST_OPERATOR_LINKAGE_ENTRY (Scan));
	    end_scan = (END_OPERATOR_LINKAGE_AREA (Scan, count));

	    while(--count >= 0)
	    {
	      Scan = ((SCHEME_OBJECT *) (word_ptr));
	      word_ptr = (NEXT_LINKAGE_OPERATOR_ENTRY (word_ptr));
	      EXTRACT_OPERATOR_LINKAGE_ADDRESS (address, Scan);
	      address = (ADDRESS_TO_DATUM ((SCHEME_OBJECT *) address));
	      address = ((long) (Relocate (address)));
	      STORE_OPERATOR_LINKAGE_ADDRESS (address, Scan);
	    }
	    Scan = &end_scan[1];
	    END_OPERATOR_RELOCATION (Scan - 1);
	    break;
	  }

	  default:
	  {
	    gc_death (TERM_EXIT,
		      "Relocate_Block: Unknown compiler linkage kind.",
		      Scan, NULL);
	    /*NOTREACHED*/
	  }
	}
	break;
      }

      case TC_MANIFEST_CLOSURE:
      {
	/* See comment about relocation in TC_LINKAGE_SECTION above. */

	fast long count;
	fast char *word_ptr;
	SCHEME_OBJECT *area_end;

	START_CLOSURE_RELOCATION (Scan);
	Scan += 1;
	count = (MANIFEST_CLOSURE_COUNT (Scan));
	word_ptr = (FIRST_MANIFEST_CLOSURE_ENTRY (Scan));
	area_end = ((MANIFEST_CLOSURE_END (Scan, count)) + 1);

	while ((--count) >= 0)
	{
	  Scan = ((SCHEME_OBJECT *) (word_ptr));
	  word_ptr = (NEXT_MANIFEST_CLOSURE_ENTRY (word_ptr));
	  EXTRACT_CLOSURE_ENTRY_ADDRESS (address, Scan);
	  address = (ADDRESS_TO_DATUM ((SCHEME_OBJECT *) address));
	  address = ((long) (Relocate (address)));
	  STORE_CLOSURE_ENTRY_ADDRESS (address, Scan);
	}
	Scan = area_end;
	END_CLOSURE_RELOCATION (Scan);
	break;
      }

#ifdef BYTE_INVERSION
      case TC_CHARACTER_STRING:
	String_Inversion (Relocate (OBJECT_DATUM (Temp)));
	goto normal_pointer;
#endif

      case TC_REFERENCE_TRAP:
	if ((OBJECT_DATUM (Temp)) <= TRAP_MAX_IMMEDIATE)
	{
	  Scan += 1;
	  break;
	}
	/* It is a pointer, fall through. */

      	/* Compiled entry points and stack environments work automagically. */
	/* This should be more strict. */

      default:
#ifdef BYTE_INVERSION
      normal_pointer:
#endif
	address = (OBJECT_DATUM (Temp));
	*Scan++ = (MAKE_POINTER_OBJECT ((OBJECT_TYPE (Temp)),
					(Relocate (address))));
	break;
      }
  }
  return;
}

static Boolean
DEFUN (check_primitive_numbers, (table, length),
       fast SCHEME_OBJECT * table AND fast long length)
{
  fast long count, top;

  top = (NUMBER_OF_DEFINED_PRIMITIVES ());
  if (length < top)
  {
    top = length;
  }

  for (count = 0; count < top; count += 1)
  {
    if (table[count] != (MAKE_PRIMITIVE_OBJECT (0, count)))
    {
      return (false);
    }
  }
  /* Is this really correct?  Can't this screw up if there
     were more implemented primitives in the dumping microcode
     than in the loading microcode and they all fell after the
     last implemented primitive in the loading microcode?
   */
  if (length == top)
  {
    return (true);
  }
  for (count = top; count < length; count += 1)
  {
    if (table[count] != (MAKE_PRIMITIVE_OBJECT (count, top)))
    {
      return (false);
    }
  }
  return (true);
}

extern void EXFUN (get_band_parameters, (long * heap_size, long * const_size));

void
DEFUN (get_band_parameters, (heap_size, const_size),
       long * heap_size AND long * const_size)
{
  /* This assumes we have just aborted out of a band load. */
  (*heap_size) = Heap_Count;
  (*const_size) = Const_Count;
}

static void
DEFUN (Intern_Block, (Next_Pointer, Stop_At),
       fast SCHEME_OBJECT * Next_Pointer AND fast SCHEME_OBJECT * Stop_At)
{
  if (Reloc_Debug)
  {
    printf ("Interning a block.\n");
  }

  while (Next_Pointer < Stop_At)
  {
    switch (OBJECT_TYPE (*Next_Pointer))
    {
      case TC_MANIFEST_NM_VECTOR:
        Next_Pointer += (1 + (OBJECT_DATUM (* Next_Pointer)));
        break;

      case TC_INTERNED_SYMBOL:
	if ((OBJECT_TYPE (MEMORY_REF (*Next_Pointer, SYMBOL_GLOBAL_VALUE))) ==
	    TC_BROKEN_HEART)
	{
	  SCHEME_OBJECT old_symbol = (*Next_Pointer);
	  MEMORY_SET (old_symbol, SYMBOL_GLOBAL_VALUE, UNBOUND_OBJECT);
	  {
	    SCHEME_OBJECT new_symbol = (intern_symbol (old_symbol));
	    if (new_symbol != old_symbol)
	      {
		(*Next_Pointer) = new_symbol;
		MEMORY_SET
		  (old_symbol,
		   SYMBOL_NAME,
		   (OBJECT_NEW_TYPE (TC_BROKEN_HEART, new_symbol)));
	      }
	  }
	}
	else if ((OBJECT_TYPE (MEMORY_REF (*Next_Pointer, SYMBOL_NAME))) ==
		TC_BROKEN_HEART)
	{
	  *Next_Pointer =
	    (MAKE_OBJECT_FROM_OBJECTS
	     ((*Next_Pointer),
	      (FAST_MEMORY_REF ((*Next_Pointer), SYMBOL_NAME))));
	}
	Next_Pointer += 1;
	break;

      default:
	Next_Pointer += 1;
	break;
    }
  }
  if (Reloc_Debug)
  {
    printf ("Done interning block.\n");
  }
  return;
}

/* This should be moved to config.h! */

#ifndef COMPUTE_RELOCATION
#define COMPUTE_RELOCATION(new, old) (((relocation_type) (new)) - (old))
#endif

static SCHEME_OBJECT
DEFUN (load_file, (mode), int mode)
{
  SCHEME_OBJECT
    *Orig_Heap,
    *Constant_End, *Orig_Constant,
    *temp, *primitive_table;

  /* Read File */

#ifdef ENABLE_DEBUGGING_TOOLS
  Warned = false;
#endif

  load_renumber_table = Free;
  Free += Primitive_Table_Length;
  ALIGN_FLOAT (Free);
  Orig_Heap = Free;
  Orig_Constant = Free_Constant;
  primitive_table = (read_file_end (mode));
  Constant_End = Free_Constant;
  heap_relocation = (COMPUTE_RELOCATION (Orig_Heap, Heap_Base));

  /*
    Magic!
    The relocation of compiled code entry points depends on the fact
    that fasdump never dumps the compiler utilities vector (which
    contains entry points used by compiled code to invoke microcode
    provided utilities, like return_to_interpreter).

    If the file is not a band, any pointers into constant space are
    pointers into the compiler utilities vector.  const_relocation is
    computed appropriately.

    Otherwise (the file is a band, and only bands can contain constant
    space segments) the utilities vector stuff is relocated
    automagically: the utilities vector is part of the band.
   */

  if ((!band_p) && (dumped_utilities != SHARP_F))
  {
    if (compiler_utilities == SHARP_F)
    {
      signal_error_from_primitive (ERR_FASLOAD_COMPILED_MISMATCH);
    }

    const_relocation =
      (COMPUTE_RELOCATION ((OBJECT_ADDRESS (compiler_utilities)),
			   (OBJECT_DATUM (dumped_utilities))));
    Dumped_Constant_Top =
      (ADDRESS_TO_DATUM
       (MEMORY_LOC (dumped_utilities,
		    (1 + (VECTOR_LENGTH (compiler_utilities))))));
  }
  else
  {
    const_relocation = (COMPUTE_RELOCATION (Orig_Constant, Const_Base));
  }
  stack_relocation = (COMPUTE_RELOCATION (Stack_Top, Dumped_Stack_Top));

#ifdef BYTE_INVERSION
  Setup_For_String_Inversion ();
#endif

  /* Setup the primitive table */

  install_primitive_table (primitive_table,
			   Primitive_Table_Length,
			   (mode == MODE_BAND));

  if ((mode != MODE_BAND)				||
      (heap_relocation != ((relocation_type) 0))	||
      (const_relocation != ((relocation_type) 0))	||
      (stack_relocation != ((relocation_type) 0))	||
      (!check_primitive_numbers(load_renumber_table,
				Primitive_Table_Length)))
  {
    /* We need to relocate.  Oh well. */
    if (Reloc_Debug)
    {
      printf ("heap_relocation = %ld = %lx; const_relocation = %ld = %lx\n",
	      ((long) heap_relocation), ((long) heap_relocation),
	      ((long) const_relocation), ((long) const_relocation));
    }

    /*
      Relocate the new data.

      There are no pointers in the primitive table, thus
      there is no need to relocate it.
      */

    Relocate_Block (Orig_Heap, primitive_table);
    Relocate_Block (Orig_Constant, Constant_End);
  }

#ifdef BYTE_INVERSION
  Finish_String_Inversion ();
#endif

  if (mode != MODE_BAND)
  {
    /* Again, there are no symbols in the primitive table. */

    Intern_Block (Orig_Heap, primitive_table);
    Intern_Block (Orig_Constant, Constant_End);
  }

  FASLOAD_RELOCATE_HOOK (Orig_Heap, primitive_table,
			 Orig_Constant, Constant_End);
  Relocate_Into (temp, Dumped_Object);
  return (*temp);
}

/* (BINARY-FASLOAD FILE-NAME-OR-CHANNEL)
   Load the contents of FILE-NAME-OR-CHANNEL into memory.  The file
   was presumably made by a call to PRIMITIVE-FASDUMP, and may contain
   data for the heap and/or the pure area.  The value returned is the
   object which was dumped.  Typically (but not always) this will be a
   piece of SCode which is then evaluated to perform definitions in
   some environment.
   If a file name is given, the corresponding file is opened before
   loading and closed after loading.  A channel remains open.
*/

DEFINE_PRIMITIVE ("BINARY-FASLOAD", Prim_binary_fasload, 1, 1, 0)
{
  SCHEME_OBJECT arg;
  PRIMITIVE_HEADER (1);
  
  PRIMITIVE_CANONICALIZE_CONTEXT();
  arg = (ARG_REF (1));
  if (STRING_P (arg))
  {
    read_file_start ((STRING_ARG (1)), false);
    PRIMITIVE_RETURN (load_file (MODE_FNAME));
  }
  else
  {
    read_channel_start ((arg_channel (1)), MODE_CHANNEL);
    PRIMITIVE_RETURN (load_file (MODE_CHANNEL));
  }
}

SCHEME_OBJECT
DEFUN (continue_fasload, (reentry_record), SCHEME_OBJECT * reentry_record)
{
  SCHEME_OBJECT header;

  /* The reentry record was prepared by read_channel_continue above. */

  load_channel = (arg_channel (1));
  header = (reentry_record[0]);
  read_channel_continue ((VECTOR_LOC (header, 0)), MODE_CHANNEL, true);
  PRIMITIVE_RETURN (load_file (MODE_CHANNEL));
}

/* Band loading. */

static char *reload_band_name = 0;
static Tptrvec reload_cleanups = 0;

DEFINE_PRIMITIVE ("RELOAD-BAND-NAME", Prim_reload_band_name, 0, 0,
  "Return the filename from which the runtime system was last restored.\n\
The result is a string, or #F if the system was not restored.")
{
  PRIMITIVE_HEADER (0);
  PRIMITIVE_RETURN
    ((reload_band_name != 0)
     ? (char_pointer_to_string ((unsigned char *) reload_band_name))
     : (option_band_file != 0)
     ? (char_pointer_to_string ((unsigned char *) option_band_file))
     : SHARP_F);
}

typedef void EXFUN ((*Tcleanup), (void));

void
DEFUN (add_reload_cleanup, (cleanup_procedure), Tcleanup cleanup_procedure)
{
  if (reload_cleanups == 0)
    {
      reload_cleanups = (ptrvec_allocate (1));
      (* ((Tcleanup *) (PTRVEC_LOC (reload_cleanups, 0)))) = cleanup_procedure;
    }
  else
    ptrvec_adjoin (reload_cleanups, cleanup_procedure);
}

void
DEFUN_VOID (execute_reload_cleanups)
{
  PTR * scan = (PTRVEC_START (reload_cleanups));
  PTR * end = (PTRVEC_END (reload_cleanups));
  while (scan < end)
    (* ((Tcleanup *) (scan++))) ();
}

/* Utility for load band below. */

void
DEFUN_VOID (compiler_reset_error)
{
  fprintf (stderr,
	   "\ncompiler_reset_error: The band being restored and\n");
  fprintf (stderr,
	   "the compiled code interface in this microcode are inconsistent.\n");
  Microcode_Termination (TERM_COMPILER_DEATH);
}

#ifndef START_BAND_LOAD
#define START_BAND_LOAD()						\
{									\
  ENTER_CRITICAL_SECTION ("band load");					\
}
#endif

#ifndef END_BAND_LOAD
#define END_BAND_LOAD(success, dying)					\
{									\
  if (success || dying)							\
    execute_reload_cleanups ();						\
  EXIT_CRITICAL_SECTION ({});						\
}
#endif

struct memmag_state
{
  SCHEME_OBJECT *free;
  SCHEME_OBJECT *memtop;
  SCHEME_OBJECT *free_constant;
  SCHEME_OBJECT *stack_pointer;
};

static void
DEFUN (abort_band_load, (ap), PTR ap)
{
  struct memmag_state * mp = ((struct memmag_state *) ap);

  Free = (mp->free);
  SET_MEMTOP (mp->memtop);
  Free_Constant = (mp->free_constant);
  Stack_Pointer = (mp->stack_pointer);

  END_BAND_LOAD (false, false);
  return;
}

static void
DEFUN (terminate_band_load, (ap), PTR ap)
{
  fputs ("\nload-band: ", stderr);
  {
    int abort_value = (abort_to_interpreter_argument ());
    if (abort_value > 0)
      fprintf (stderr, "Error %ld (%s)",
	       ((long) abort_value),
	       (Error_Names [abort_value]));
    else
      fprintf (stderr, "Abort %ld (%s)",
	       ((long) abort_value),
	       (Abort_Names [(-abort_value) - 1]));
  }
  fputs (" past the point of no return.\n", stderr);
  {
    char * band_name = (* ((char **) ap));
    if (band_name != 0)
      {
	fprintf (stderr, "band-name = \"%s\".\n", band_name);
	free (band_name);
      }
  }
  fflush (stderr);
  END_BAND_LOAD (false, true);
  Microcode_Termination (TERM_DISK_RESTORE);
  /*NOTREACHED*/
}

/* (LOAD-BAND FILE-NAME)
   Restores the heap and pure space from the contents of FILE-NAME,
   which is typically a file created by DUMP-BAND.  The file can,
   however, be any file which can be loaded with BINARY-FASLOAD.
*/

DEFINE_PRIMITIVE ("LOAD-BAND", Prim_band_load, 1, 1, 0)
{
  SCHEME_OBJECT result;
  PRIMITIVE_HEADER (1);
  PRIMITIVE_CANONICALIZE_CONTEXT ();
  {
    CONST char * file_name = (STRING_ARG (1));
    transaction_begin ();
    {
      struct memmag_state * ap = (dstack_alloc (sizeof (struct memmag_state)));
      ap->free = Free;
      ap->memtop = MemTop;
      ap->free_constant = Free_Constant;
      ap->stack_pointer = Stack_Pointer;
      transaction_record_action (tat_abort, abort_band_load, ap);
    }  
    Free = Heap_Bottom;
    SET_MEMTOP (Heap_Top);
    START_BAND_LOAD ();
    Free_Constant = Constant_Space;
    Stack_Pointer = Highest_Allocated_Address;
    read_file_start (file_name, true);
    transaction_commit ();

    /* Point of no return. */
    {
      long length = ((strlen (file_name)) + 1);
      char * band_name = (malloc (length));
      if (band_name != 0)
      {
	strcpy (band_name, file_name);
      }
      transaction_begin ();
      {
	char ** ap = (dstack_alloc (sizeof (char *)));
	(*ap) = band_name;
	transaction_record_action (tat_abort, terminate_band_load, ap);
      }
      result = (load_file (MODE_BAND));
      transaction_commit ();
      if (reload_band_name != 0)
      {
	free (reload_band_name);
      }
      reload_band_name = band_name;
    }
  }
  /* Reset implementation state paramenters */
  INITIALIZE_INTERRUPTS ();
  Initialize_Stack ();
  SET_MEMTOP (Heap_Top - GC_Reserve);
  {
    SCHEME_OBJECT cutl = (MEMORY_REF (result, 1));
    if (cutl != SHARP_F)
      {
	compiler_utilities = cutl;
	compiler_reset (cutl);
      }
    else
      compiler_initialize (true);
  }
  Restore_Fixed_Obj (SHARP_F);
  Fluid_Bindings = EMPTY_LIST;
  Current_State_Point = SHARP_F;
  /* Setup initial program */
  Store_Return (RC_END_OF_COMPUTATION);
  Store_Expression (SHARP_F);
  Save_Cont ();
  Store_Expression (MEMORY_REF (result, 0));
  Store_Env (MAKE_OBJECT (GLOBAL_ENV, GO_TO_GLOBAL));
  /* Clear various interpreter state parameters. */
  Trapping = false;
  Return_Hook_Address = 0;
  History = (Make_Dummy_History ());
  Prev_Restore_History_Stacklet = 0;
  Prev_Restore_History_Offset = 0;
  COMPILER_TRANSPORT_END ();
  END_BAND_LOAD (true, false);
  Band_Load_Hook ();
  /* Return in a non-standard way. */
  PRIMITIVE_ABORT (PRIM_DO_EXPRESSION);
  /*NOTREACHED*/
}

#ifdef BYTE_INVERSION

#define MAGIC_OFFSET (TC_FIXNUM + 1)

SCHEME_OBJECT String_Chain, Last_String;

void
DEFUN_VOID (Setup_For_String_Inversion)
{
  String_Chain = SHARP_F;
  Last_String = SHARP_F;
  return;
}

void
DEFUN_VOID (Finish_String_Inversion)
{
  if (Byte_Invert_Fasl_Files)
  {
    while (String_Chain != SHARP_F)
    {
      long Count;
      SCHEME_OBJECT Next;

      Count = OBJECT_DATUM (FAST_MEMORY_REF (String_Chain, STRING_HEADER));
      Count = 4 * (Count - 2) + (OBJECT_TYPE (String_Chain)) - MAGIC_OFFSET;
      if (Reloc_Debug)
      {
	printf ("String at 0x%lx: restoring length of %ld.\n",
		((long) (OBJECT_ADDRESS (String_Chain))),
		((long) Count));
      }
      Next = (STRING_LENGTH (String_Chain));
      SET_STRING_LENGTH (String_Chain, Count);
      String_Chain = Next;
    }
  }
  return;
}

#define print_char(C) printf (((C < ' ') || (C > '|')) ?	\
			      "\\%03o" : "%c", (C && MAX_CHAR));

void
DEFUN (String_Inversion, (Orig_Pointer), SCHEME_OBJECT * Orig_Pointer)
{
  SCHEME_OBJECT *Pointer_Address;
  char *To_Char;
  long Code;

  if (!Byte_Invert_Fasl_Files)
  {
    return;
  }

  Code = OBJECT_TYPE (Orig_Pointer[STRING_LENGTH_INDEX]);
  if (Code == 0)	/* Already reversed? */
  {
    long Count, old_size, new_size, i;

    old_size = (OBJECT_DATUM (Orig_Pointer[STRING_HEADER]));
    new_size =
      2 + (((long) (Orig_Pointer[STRING_LENGTH_INDEX]))) / 4;

    if (Reloc_Debug)
    {
      printf ("\nString at 0x%lx with %ld characters",
	      ((long) Orig_Pointer),
	      ((long) (Orig_Pointer[STRING_LENGTH_INDEX])));
    }

    if (old_size != new_size)
    {
      printf ("\nWord count changed from %ld to %ld: ",
	      ((long) old_size), ((long) new_size));
      printf ("\nWhich, of course, is impossible!!\n");
      Microcode_Termination (TERM_EXIT);
    }

    Count = ((long) (Orig_Pointer[STRING_LENGTH_INDEX])) % 4;
    if (Count == 0)
    {
      Count = 4;
    }
    if (Last_String == SHARP_F)
    {
      String_Chain = MAKE_POINTER_OBJECT (Count + MAGIC_OFFSET, Orig_Pointer);
    }
    else
    {
      FAST_MEMORY_SET
	(Last_String, STRING_LENGTH_INDEX,
	 (MAKE_POINTER_OBJECT ((Count + MAGIC_OFFSET), Orig_Pointer)));
    }

    Last_String = (MAKE_POINTER_OBJECT (TC_NULL, Orig_Pointer));
    Orig_Pointer[STRING_LENGTH_INDEX] = SHARP_F;
    Count = (OBJECT_DATUM (Orig_Pointer[STRING_HEADER])) - 1;
    if (Reloc_Debug)
    {
       printf ("\nCell count = %ld\n", ((long) Count));
     }
    Pointer_Address = &(Orig_Pointer[STRING_CHARS]);
    To_Char = (char *) Pointer_Address;
    for (i = 0; i < Count; i++, Pointer_Address++)
    {
      int C1, C2, C3, C4;

      C4 = OBJECT_TYPE (*Pointer_Address) & 0xFF;
      C3 = (((long) *Pointer_Address)>>16) & 0xFF;
      C2 = (((long) *Pointer_Address)>>8) & 0xFF;
      C1 = ((long) *Pointer_Address) & 0xFF;
      if (Reloc_Debug || (old_size != new_size))
      {
	print_char(C1);
        print_char(C2);
        print_char(C3);
        print_char(C4);
      }
      *To_Char++ = C1;
      *To_Char++ = C2;
      *To_Char++ = C3;
      *To_Char++ = C4;
    }
  }
  if (Reloc_Debug)
  {
    printf ("\n");
  }
  return;
}
#endif /* BYTE_INVERSION */
