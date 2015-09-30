#include "lockfile.h"
	/* skip leading whitespaces, if both begin with whitespace */
	if (s1 <= last1 && s2 <= last2 && isspace(*s1) && isspace(*s2)) {
		while (isspace(*s1) && (s1 <= last1))
			s1++;
		while (isspace(*s2) && (s2 <= last2))
			s2++;
	}
	return skip_prefix(str, "/dev/null", &str) && isspace(*str);
		return squash_slash(xstrdup_or_null(def));
		return squash_slash(xstrdup_or_null(def));
			patch->new_name = xstrdup_or_null(name);
	patch->old_name = xstrdup_or_null(patch->def_name);
	patch->new_name = xstrdup_or_null(patch->def_name);
	eol = strchrnul(line, '\n');
		char *s = xstrfmt("%s%s", root, patch->def_name);
			ret = size < 3 || !starts_with(line, "@@ ");
			ret = size < 5 || !starts_with(line, "diff ");
	if (starts_with(buffer, "delta ")) {
	else if (starts_with(buffer, "literal ")) {
static void prefix_one(char **name)
{
	char *old_name = *name;
	if (!old_name)
		return;
	*name = xstrdup(prefix_filename(prefix, prefix_length, *name));
	free(old_name);
}

static void prefix_patch(struct patch *p)
{
	if (!prefix || p->is_toplevel_relative)
		return;
	prefix_one(&p->new_name);
	prefix_one(&p->old_name);
}

/*
 * include/exclude
 */

static struct string_list limit_by_name;
static int has_include;
static void add_name_limit(const char *name, int exclude)
{
	struct string_list_item *it;

	it = string_list_append(&limit_by_name, name);
	it->util = exclude ? NULL : (void *) 1;
}

static int use_patch(struct patch *p)
{
	const char *pathname = p->new_name ? p->new_name : p->old_name;
	int i;

	/* Paths outside are not touched regardless of "--include" */
	if (0 < prefix_length) {
		int pathlen = strlen(pathname);
		if (pathlen <= prefix_length ||
		    memcmp(prefix, pathname, prefix_length))
			return 0;
	}

	/* See if it matches any of exclude/include rule */
	for (i = 0; i < limit_by_name.nr; i++) {
		struct string_list_item *it = &limit_by_name.items[i];
		if (!wildmatch(it->string, pathname, 0, NULL))
			return (it->util != NULL);
	}

	/*
	 * If we had any include, a path that does not match any rule is
	 * not used.  Otherwise, we saw bunch of exclude rules (or none)
	 * and such a path is used.
	 */
	return !has_include;
}


	prefix_patch(patch);

	if (!use_patch(patch))
		patch->ws_rule = 0;
	else
		patch->ws_rule = whitespace_rule(patch->new_name
						 ? patch->new_name
						 : patch->old_name);
			static const char *binhdr[] = {
				"Binary files ",
				"Files ",
				NULL,
			};
			int i;
	if (postlen
	    ? postlen < new - postimage->buf
	    : postimage->len < new - postimage->buf)
		die("BUG: caller miscounted postlen: asked %d, orig = %d, used = %d",
		    (int)postlen, (int) postimage->len, (int)(new - postimage->buf));

	 * it might with whitespace fuzz. We weren't asked to
	 * While checking the preimage against the target, whitespace
	 * errors in both fixed, we count how large the corresponding
	 * postimage needs to be.  The postimage prepared by
	 * apply_one_fragment() has whitespace errors fixed on added
	 * lines already, but the common lines were propagated as-is,
	 * which may become longer when their whitespace errors are
	 * fixed.
	 */

	/* First count added lines in postimage */
	postlen = 0;
	for (i = 0; i < postimage->nr; i++) {
		if (!(postimage->line[i].flag & LINE_COMMON))
			postlen += postimage->line[i].len;
	}

	/*

		/* Add the length if this is common with the postimage */
		if (preimage->line[i].flag & LINE_COMMON)
			postlen += tgtfix.len;
		REALLOC_ARRAY(img->line, nr);
		img->buf = xmemdupz(fragment->patch, img->len);
static int read_file_or_gitlink(const struct cache_entry *ce, struct strbuf *buf)
static int checkout_target(struct index_state *istate,
			   struct cache_entry *ce, struct stat *st)
	costate.istate = istate;
static int verify_index_match(const struct cache_entry *ce, struct stat *st)
			     const struct cache_entry *ce,
			 struct patch *patch, struct stat *st,
			 const struct cache_entry *ce)
		if (checkout_target(&the_index, ce, &st))
			struct stat *st, const struct cache_entry *ce)
static int apply_data(struct patch *patch, struct stat *st, const struct cache_entry *ce)
			if (checkout_target(&the_index, *ce, st))
	    starts_with(++preimage, heading) &&
	    starts_with(preimage + sizeof(heading) - 1, p->old_sha1_prefix))
	static struct lock_file lock;
				die("sha1 information is lacking or useless for submodule %s",
	hold_lock_file_for_update(&lock, filename, LOCK_DIE_ON_ERROR);
	if (write_locked_index(&result, &lock, COMMIT_LOCK))
		const char *s;
		if (!skip_prefix(buf, "Subproject commit ", &s) ||
		    get_sha1_hex(s, ce->sha1))
			die(_("corrupt patch for submodule %s"), path);
	 * this is a git patch by saying --git or giving extended
		string_list_sort(&cpath);
static void git_apply_config(void)
	git_config_get_string_const("apply.whitespace", &apply_default_whitespace);
	git_config_get_string_const("apply.ignorewhitespace", &apply_default_ignorewhitespace);
	git_config(git_default_config, NULL);
		OPT_BOOL(0, "no-add", &no_add,
		OPT_BOOL(0, "stat", &diffstat,
		OPT_BOOL(0, "numstat", &numstat,
		OPT_BOOL(0, "summary", &summary,
		OPT_BOOL(0, "check", &check,
		OPT_BOOL(0, "index", &check_index,
		OPT_BOOL(0, "cached", &cached,
		OPT_BOOL(0, "apply", &force_apply,
		OPT_BOOL('R', "reverse", &apply_in_reverse,
		OPT_BOOL(0, "unidiff-zero", &unidiff_zero,
		OPT_BOOL(0, "reject", &apply_with_reject,
		OPT_BOOL(0, "allow-overlap", &allow_overlap,
	git_apply_config();
		if (write_locked_index(&the_index, &lock_file, COMMIT_LOCK))