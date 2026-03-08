import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/overseerr/core/state.dart';
import 'package:lunasea/modules/overseerr/core/models/search_result.dart';

class OverseerrSearchPage extends StatefulWidget {
  const OverseerrSearchPage({
    Key? key,
  }) : super(key: key);

  @override
  State<OverseerrSearchPage> createState() => _OverseerrSearchPageState();
}

class _OverseerrSearchPageState extends State<OverseerrSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: _appBar(),
      body: _body(context),
    );
  }

  PreferredSizeWidget _appBar() {
    return LunaAppBar(
      title: 'Search Overseerr',
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(LunaTextInputBar.defaultAppBarHeight),
        child: LunaTextInputBar(
          controller: _searchController,
          scrollController: _scrollController,
          onChanged: (value) {
            if (value.length > 2) {
              context.read<OverseerrState>().search(value);
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              context.read<OverseerrState>().search(value);
            }
          },
          margin: LunaTextInputBar.appBarMargin,
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final state = context.watch<OverseerrState>();

    if (state.searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty ? 'Search for movies or TV shows' : 'No results found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) => _resultTile(context, state.searchResults[index]),
    );
  }

  Widget _resultTile(BuildContext context, OverseerrSearchResult result) {
    return LunaBlock(
      title: result.title,
      body: [
        TextSpan(text: '${result.mediaType.toUpperCase()} - ${result.releaseDate}'),
        TextSpan(text: result.overview),
      ],
      customBodyMaxLines: 3,
      posterUrl: result.posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w600_and_h900_bestv2${result.posterPath}' : null,
      onTap: () => _requestMedia(context, result),
    );
  }

  Future<void> _requestMedia(BuildContext context, OverseerrSearchResult result) async {
    final state = context.read<OverseerrState>();
    bool _is4k = false;

    bool? confirm = await LunaDialog.dialog<bool>(
      context: context,
      title: 'Request Media',
      customContent: StatefulBuilder(
        builder: (context, setState) => LunaDialog.content(
          children: [
            LunaDialog.textContent(text: 'Are you sure you want to request "${result.title}"?'),
            const SizedBox(height: 12.0),
            LunaDialog.checkbox(
              title: 'Request 4K',
              value: _is4k,
              onChanged: (value) => setState(() => _is4k = value ?? false),
            ),
          ],
        ),
      ),
      buttons: [
        LunaDialog.button(
          text: 'Request',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      contentPadding: LunaDialog.textDialogContentPadding(),
    ) as bool?;

    if (confirm == true) {
      if (await state.requestMedia(
        tmdbId: result.id,
        mediaType: result.mediaType,
        is4k: _is4k,
      )) {
        showLunaSuccessSnackBar(title: 'Request Sent', message: 'Successfully requested "${result.title}"');
      } else {
        showLunaErrorSnackBar(title: 'Request Failed', message: 'Failed to request "${result.title}"');
      }
    }
  }
}
