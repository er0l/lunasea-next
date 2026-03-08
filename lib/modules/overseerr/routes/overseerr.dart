import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules.dart';
import 'package:lunasea/modules/overseerr/routes.dart';
import 'package:lunasea/modules/overseerr/core/state.dart';
import 'package:lunasea/modules/overseerr/core/models/media_request.dart';

class OverseerrPage extends StatefulWidget {
  final bool showDrawer;

  const OverseerrPage({
    Key? key,
    this.showDrawer = true,
  }) : super(key: key);

  @override
  State<OverseerrPage> createState() => _OverseerrPageState();
}

class _OverseerrPageState extends State<OverseerrPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<OverseerrState>().fetchRequests());
  }

  @override
  Widget build(BuildContext context) {
    return LunaScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: _appBar(),
      body: _body(context),
      drawer: widget.showDrawer ? LunaDrawer(page: LunaModule.OVERSEERR.key) : null,
      floatingActionButton: _fab(context),
    );
  }

  PreferredSizeWidget _appBar() {
    return LunaAppBar(
      title: LunaModule.OVERSEERR.title,
      useDrawer: widget.showDrawer,
      hideLeading: !widget.showDrawer,
    );
  }

  Widget _fab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push('/overseerr/search'),
      child: const Icon(Icons.search_rounded),
      backgroundColor: LunaModule.OVERSEERR.color,
    );
  }

  Widget _body(BuildContext context) {
    final state = context.watch<OverseerrState>();

    if (state.fetching && state.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error && state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.errorMessage}'),
            const SizedBox(height: 16.0),
            LunaButton.text(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: () => state.fetchRequests(),
            ),
          ],
        ),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LunaModule.OVERSEERR.icon,
              size: 64.0,
              color: LunaModule.OVERSEERR.color.withOpacity(0.5),
            ),
            const SizedBox(height: 16.0),
            Text(
              'No requests found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => state.fetchRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        itemCount: state.requests.length,
        itemBuilder: (context, index) => _requestTile(context, state.requests[index]),
      ),
    );
  }

  Widget _requestTile(BuildContext context, OverseerrMediaRequest request) {
    return LunaBlock(
      title: request.title,
      body: [
        TextSpan(
          text: '${request.mediaType.toUpperCase()} - Requested by ${request.requestedBy}',
        ),
      ],
      trailing: InkWell(
        onTap: () => _showRequestDetails(context, request),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: request.statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            request.statusText,
            style: TextStyle(
              color: request.statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ),
      ),
      onTap: () => _showMediaDetails(context, request),
    );
  }

  Future<void> _showMediaDetails(BuildContext context, OverseerrMediaRequest request) async {
    await LunaDialog.dialog(
      context: context,
      title: 'Media Information',
      contentPadding: LunaDialog.textDialogContentPadding(),
      customContent: LunaDialog.content(
        children: [
          LunaDialog.richText(
            children: [
              LunaDialog.bolded(
                text: request.title,
                fontSize: 18.0,
                color: Colors.white,
              ),
            ],
            alignment: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          if (request.posterPath.isNotEmpty) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LunaUI.BORDER_RADIUS),
                child: Image.network(
                  'https://image.tmdb.org/t/p/w600_and_h900_bestv2${request.posterPath}',
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
          if (request.overview.isNotEmpty) ...[
            LunaDialog.textContent(
              text: request.overview,
              textAlign: TextAlign.start,
            ),
          ] else ...[
            LunaDialog.richText(
              children: [
                TextSpan(
                  text: 'No summary available.',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ],
              alignment: TextAlign.start,
            ),
          ],
        ],
      ),
      buttons: [
        LunaDialog.button(
          text: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _showRequestDetails(BuildContext context, OverseerrMediaRequest request) async {
    await LunaDialog.dialog(
      context: context,
      title: 'Request Information',
      contentPadding: LunaDialog.textDialogContentPadding(),
      customContent: LunaDialog.content(
        children: [
          LunaDialog.richText(
            children: [
              LunaDialog.bolded(text: 'Title: '),
              LunaDialog.textSpanContent(text: request.title),
            ],
          ),
          LunaDialog.richText(
            children: [
              LunaDialog.bolded(text: 'Type: '),
              LunaDialog.textSpanContent(text: request.mediaType.toUpperCase()),
            ],
          ),
          LunaDialog.richText(
            children: [
              LunaDialog.bolded(text: 'Requested By: '),
              LunaDialog.textSpanContent(text: request.requestedBy),
            ],
          ),
          LunaDialog.richText(
            children: [
              LunaDialog.bolded(text: 'Status: '),
              LunaDialog.bolded(
                text: request.statusText,
                color: request.statusColor,
              ),
            ],
          ),
          LunaDialog.richText(
            children: [
              LunaDialog.bolded(text: 'Date: '),
              LunaDialog.textSpanContent(text: request.createdAt.toString().split('.')[0]),
            ],
          ),
        ],
      ),
      buttons: [
        LunaDialog.button(
          text: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
