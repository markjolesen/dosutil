/*
 CMP.C

 License CC0 PUBLIC DOMAIN

 To the extent possible under law, Mark J. Olesen has waived all copyright 
 and related or neighboring rights to LS. This work is published 
 from: United States.
*/

#pragma pack(push, 1)
struct file_info 
{
    unsigned char                       fi_attr;
    unsigned short int                  fi_time;
    unsigned short int                  fi_date;
    unsigned long int                   fi_size;
    char                                fi_name[13];
};
#pragma pack(pop)

extern unsigned char                    opt_r;

extern int
filebuf_compare_fn(
    struct file_info const __far*       a,
    struct file_info const __far*       b);

extern int
compare_size(
    struct file_info const __far*       a,
    struct file_info const __far*       b)
{
    int                                 l_exit;

    if ((*a).fi_size > (*b).fi_size)
    {
        l_exit= (opt_r) ? -1 : 1;
    }
    else if ((*a).fi_size < (*b).fi_size)
    {
        l_exit= (opt_r) ? 1 : -1;
    }
    else
    {
        l_exit= filebuf_compare_fn(a, b);
    }

    return l_exit;
}

extern int
compare_time(
    struct file_info const __far*       a,
    struct file_info const __far*       b)
{
    int                                 l_exit;

    if ((*a).fi_date > (*b).fi_date)
    {
        l_exit= (opt_r) ? -1 : 1;
    }
    else if ((*a).fi_date < (*b).fi_date)
    {
        l_exit= (opt_r) ? 1 : -1;
    }
    else
    {
        if ((*a).fi_time > (*b).fi_time)
        {
            l_exit= (opt_r) ? -1 : 1;
        }
        else if ((*a).fi_time < (*b).fi_time)
        {
            l_exit= (opt_r) ? 1 : -1;
        }
        else
        {
            l_exit= filebuf_compare_fn(a, b);
        }
    }

    return l_exit;
}
