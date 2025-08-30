// SPDX-License-Identifier: AGPL-3.0-only

enum ListenedCriteria {
  all,
  listened,
  notListened
}

enum EntryType {
  releaseGroup,
  artist
}

enum ArtistListFilter {
  none,
  inWhitelist,
  inBlacklist,
  notInWhitelist,
  notInBlacklist,
  inList,
  notInList
}

enum ListSortParam {
  name,
  releaseDate,
  latestListenDate,
  listensTotal,
  listensWeek,
  listensMonth,
  listensYear
}

enum IgnoredInclusion {
  include,
  includeOnly,
  exclude
}
