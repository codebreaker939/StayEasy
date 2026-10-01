import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/stayeasy_breakpoints.dart';
import '../../../core/theme/stayeasy_colors.dart';
import '../../../core/theme/stayeasy_elevation.dart';
import '../../../core/theme/stayeasy_radii.dart';
import '../../../core/theme/stayeasy_spacing.dart';
import '../../../core/theme/stayeasy_typography.dart';
import '../../auth/domain/auth_repository.dart';
import '../../booking/application/booking_provider.dart';
import '../data/admin_repository.dart';

enum AdminSection { dashboard, hotels, rooms, availability, bookings, reviews }

const _sections = <AdminSection>[
  AdminSection.dashboard,
  AdminSection.hotels,
  AdminSection.rooms,
  AdminSection.availability,
  AdminSection.bookings,
  AdminSection.reviews,
];

String _label(AdminSection section) => switch (section) {
  AdminSection.dashboard => 'Dashboard',
  AdminSection.hotels => 'Hotels',
  AdminSection.rooms => 'Rooms',
  AdminSection.availability => 'Availability',
  AdminSection.bookings => 'Bookings',
  AdminSection.reviews => 'Reviews',
};

String _path(AdminSection section) => switch (section) {
  AdminSection.dashboard => AppRoutes.admin,
  AdminSection.hotels => AppRoutes.adminHotels,
  AdminSection.rooms => AppRoutes.adminRooms,
  AdminSection.availability => AppRoutes.adminAvailability,
  AdminSection.bookings => AppRoutes.adminBookings,
  AdminSection.reviews => AppRoutes.adminReviews,
};

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const _AdminShell(
    section: AdminSection.dashboard,
    child: _DashboardBody(),
  );
}

class AdminDataPage extends StatelessWidget {
  const AdminDataPage({super.key, required this.section});
  final AdminSection section;
  @override
  Widget build(BuildContext context) => _AdminShell(
    section: section,
    child: _AdminListBody(section: section),
  );
}

class _AdminShell extends ConsumerWidget {
  const _AdminShell({required this.section, required this.child});
  final AdminSection section;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProfileProvider);
    if (profile.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = profile.value;
    if (user == null || !user.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(
            '${AppRoutes.signIn}?next=${Uri.encodeComponent(AppRoutes.admin)}',
          );
        }
      });
      return const Scaffold(
        body: Center(child: Text('Checking administrator access…')),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final layout = StayEasyBreakpoints.classify(width);
    final expanded = layout == StayEasyLayoutSize.expanded;
    final sidebar = _AdminSidebar(section: section, user: user);
    if (!expanded) {
      return Scaffold(
        backgroundColor: StayEasyColors.background,
        drawer: layout == StayEasyLayoutSize.compact
            ? Drawer(child: SafeArea(child: sidebar))
            : null,
        appBar: AppBar(
          backgroundColor: StayEasyColors.background,
          title: const Text('StayEasy Admin'),
          actions: [
            CircleAvatar(
              radius: 16,
              child: Text(
                (user.fullName ?? user.email).characters.first.toUpperCase(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.invalidate(authProfileProvider);
                if (context.mounted) context.go(AppRoutes.explore);
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Column(
          children: [
            if (layout == StayEasyLayoutSize.medium)
              _CompactAdminNavigation(section: section),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: StayEasyColors.background,
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(width: 248, child: sidebar),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({required this.section, required this.user});
  final AdminSection section;
  final StayEasyProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    decoration: const BoxDecoration(
      color: StayEasyColors.surface,
      border: Border(right: BorderSide(color: StayEasyColors.border)),
    ),
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.hotel_class_rounded, color: StayEasyColors.primary),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('StayEasy', style: StayEasyTypography.titleLarge),
                Text('Admin portal', style: StayEasyTypography.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 48),
        for (final item in _sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AdminNavItem(
              section: item,
              selected: item == section,
              onTap: () => context.go(_path(item)),
            ),
          ),
        const Spacer(),
        const Divider(color: StayEasyColors.border),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: StayEasyColors.surfaceVariant,
              child: Text(
                (user.fullName ?? user.email).characters.first.toUpperCase(),
                style: const TextStyle(color: StayEasyColors.primaryDark),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? 'Admin user',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StayEasyTypography.labelLarge,
                  ),
                  const Text(
                    'Administrator',
                    style: StayEasyTypography.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.invalidate(authProfileProvider);
                if (context.mounted) context.go(AppRoutes.explore);
              },
              icon: const Icon(Icons.logout_rounded, size: 19),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });
  final AdminSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? StayEasyColors.surfaceVariant : Colors.transparent,
    borderRadius: StayEasyRadii.rounded12,
    child: InkWell(
      borderRadius: StayEasyRadii.rounded12,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (selected)
              Container(
                width: 3,
                height: 24,
                decoration: BoxDecoration(
                  color: StayEasyColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              const SizedBox(width: 3),
            const SizedBox(width: 8),
            Icon(
              _icon(section),
              size: 19,
              color: selected
                  ? StayEasyColors.primary
                  : StayEasyColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _label(section),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StayEasyTypography.labelLarge.copyWith(
                  color: selected
                      ? StayEasyColors.primary
                      : StayEasyColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CompactAdminNavigation extends StatelessWidget {
  const _CompactAdminNavigation({required this.section});
  final AdminSection section;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      children: [
        for (final item in _sections)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 160,
              child: _AdminNavItem(
                section: item,
                selected: item == section,
                onTap: () => context.go(_path(item)),
              ),
            ),
          ),
      ],
    ),
  );
}

IconData _icon(AdminSection section) => switch (section) {
  AdminSection.dashboard => Icons.dashboard_outlined,
  AdminSection.hotels => Icons.hotel_outlined,
  AdminSection.rooms => Icons.bed_outlined,
  AdminSection.availability => Icons.calendar_month_outlined,
  AdminSection.bookings => Icons.confirmation_number_outlined,
  AdminSection.reviews => Icons.reviews_outlined,
};

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(adminRepositoryProvider);
    if (repo == null) {
      final expanded =
          MediaQuery.sizeOf(context).width >= StayEasyBreakpoints.expandedStart;
      return ListView(
        padding: EdgeInsets.fromLTRB(
          expanded ? StayEasySpacing.space40 : StayEasySpacing.space24,
          StayEasySpacing.space32,
          expanded ? StayEasySpacing.space40 : StayEasySpacing.space24,
          StayEasySpacing.space40,
        ),
        children: const [
          AdminPageHeader(
            title: 'Dashboard',
            subtitle: 'Manage StayEasy operations at a glance.',
          ),
          SizedBox(height: 24),
          _AdminSurface(
            child: _EmptyState(
              message:
                  'Connect StayEasy to Supabase to open the admin workspace.',
            ),
          ),
        ],
      );
    }
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        repo.countActiveHotels(),
        repo.countRooms(),
        repo.countUpcomingBookings(),
        repo.countReviews(),
        repo.bookings(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load dashboard data.'));
        }
        final data = snapshot.data!;
        final recent = data[4] as List<Map<String, dynamic>>;
        final width = MediaQuery.sizeOf(context).width;
        final expanded = width >= StayEasyBreakpoints.expandedStart;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            expanded ? StayEasySpacing.space40 : StayEasySpacing.space24,
            StayEasySpacing.space32,
            expanded ? StayEasySpacing.space40 : StayEasySpacing.space24,
            StayEasySpacing.space40,
          ),
          children: [
            const AdminPageHeader(
              title: 'Dashboard',
              subtitle: 'Manage StayEasy operations at a glance.',
              trailing: _LiveDataPill(),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                crossAxisCount: constraints.maxWidth >= 960
                    ? 4
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: constraints.maxWidth >= 960
                    ? 2.02
                    : constraints.maxWidth >= 560
                    ? 2.3
                    : 3.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    'Active hotels',
                    '${data[0]}',
                    Icons.hotel_outlined,
                  ),
                  _MetricCard('Rooms', '${data[1]}', Icons.bed_outlined),
                  _MetricCard(
                    'Confirmed bookings',
                    '${data[2]}',
                    Icons.confirmation_number_outlined,
                  ),
                  _MetricCard(
                    'Guest reviews',
                    '${data[3]}',
                    Icons.reviews_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final recentPanel = _RecentBookingsPanel(bookings: recent);
                final operationsPanel = _OperationsSummary(
                  hotels: data[0] as int,
                  rooms: data[1] as int,
                  bookings: data[2] as int,
                  reviews: data[3] as int,
                );
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      SizedBox(height: 420, child: recentPanel),
                      const SizedBox(height: 20),
                      SizedBox(height: 420, child: operationsPanel),
                    ],
                  );
                }
                return SizedBox(
                  height: 560,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: recentPanel),
                      const SizedBox(width: 20),
                      Expanded(child: operationsPanel),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _AdminSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: StayEasyColors.primary, size: 20),
            const Spacer(),
            Text(value, style: StayEasyTypography.headingH2),
          ],
        ),
        const Spacer(),
        Text(label, style: StayEasyTypography.bodyMedium),
      ],
    ),
  );
}

class _RecentBookingsPanel extends StatelessWidget {
  const _RecentBookingsPanel({required this.bookings});
  final List<Map<String, dynamic>> bookings;
  @override
  Widget build(BuildContext context) => _AdminSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeading(title: 'Recent bookings', action: 'View all'),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          const Expanded(child: _EmptyState(message: 'No bookings yet.'))
        else
          Expanded(
            child: ListView.separated(
              itemCount: bookings.take(8).length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = bookings[index];
                final hotel = row['hotels'] as Map?;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      const _LeadingIcon(icon: Icons.luggage_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${row['booking_code']}',
                              style: StayEasyTypography.labelLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${row['guest_name']} · ${hotel?['name'] ?? 'Hotel'}${hotel?['city'] == null ? '' : ', ${hotel?['city']}'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StayEasyTypography.bodySmall.copyWith(
                                color: StayEasyColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${row['check_in']} — ${row['check_out']}',
                              style: StayEasyTypography.caption.copyWith(
                                color: StayEasyColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${row['total_price']}',
                        style: StayEasyTypography.labelLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}

class _OperationsSummary extends StatelessWidget {
  const _OperationsSummary({
    required this.hotels,
    required this.rooms,
    required this.bookings,
    required this.reviews,
  });
  final int hotels, rooms, bookings, reviews;
  @override
  Widget build(BuildContext context) => _AdminSurface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeading(title: 'Operations summary'),
        const SizedBox(height: 8),
        Text(
          'Live catalog and guest activity',
          style: StayEasyTypography.bodySmall.copyWith(
            color: StayEasyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _SummaryRow(
          icon: Icons.hotel_outlined,
          label: 'Active hotels',
          value: '$hotels',
        ),
        _SummaryRow(
          icon: Icons.bed_outlined,
          label: 'Rooms in inventory',
          value: '$rooms',
        ),
        _SummaryRow(
          icon: Icons.confirmation_number_outlined,
          label: 'Upcoming stays',
          value: '$bookings',
        ),
        _SummaryRow(
          icon: Icons.reviews_outlined,
          label: 'Guest reviews',
          value: '$reviews',
        ),
        const Spacer(),
        const Divider(),
        Text('Quick access', style: StayEasyTypography.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in [
              AdminSection.hotels,
              AdminSection.rooms,
              AdminSection.availability,
              AdminSection.bookings,
              AdminSection.reviews,
            ])
              ActionChip(
                label: Text(_label(item)),
                onPressed: () => context.go(_path(item)),
              ),
          ],
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(icon, color: StayEasyColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: StayEasyTypography.labelLarge),
      ],
    ),
  );
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: StayEasyTypography.headingH1),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: StayEasyTypography.bodyMedium.copyWith(
                color: StayEasyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 12), trailing!],
    ],
  );
}

class _LiveDataPill extends StatelessWidget {
  const _LiveDataPill();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: StayEasyColors.surfaceVariant,
      borderRadius: StayEasyRadii.rounded12,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: StayEasyColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('Live data', style: StayEasyTypography.labelMedium),
      ],
    ),
  );
}

class _AdminSurface extends StatelessWidget {
  const _AdminSurface({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: StayEasyColors.surface,
      border: Border.all(color: StayEasyColors.border),
      borderRadius: StayEasyRadii.rounded20,
      boxShadow: StayEasyElevation.level0,
    ),
    child: child,
  );
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({required this.title, this.action});
  final String title;
  final String? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: StayEasyTypography.titleLarge)),
      if (action != null)
        TextButton(
          onPressed: () => context.go(AppRoutes.adminBookings),
          child: Text(action!),
        ),
    ],
  );
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: StayEasyColors.surfaceVariant,
      borderRadius: StayEasyRadii.rounded12,
    ),
    child: Icon(icon, size: 19, color: StayEasyColors.primary),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: StayEasyTypography.bodyMedium.copyWith(
          color: StayEasyColors.textSecondary,
        ),
      ),
    ),
  );
}

class _AdminListBody extends ConsumerStatefulWidget {
  const _AdminListBody({required this.section});
  final AdminSection section;
  @override
  ConsumerState<_AdminListBody> createState() => _AdminListBodyState();
}

class _AdminListBodyState extends ConsumerState<_AdminListBody> {
  String status = 'all';
  String month = 'all';
  String city = 'all';
  String roomFilter = 'all';
  String search = '';
  String? hotelFilter;
  late Future<List<Map<String, dynamic>>> future;
  late Future<List<Map<String, dynamic>>> hotelOptions;
  late Future<List<Map<String, dynamic>>> roomOptions;

  @override
  void initState() {
    super.initState();
    future = _load();
    hotelOptions =
        ref.read(adminRepositoryProvider)?.hotels() ?? Future.value(const []);
    roomOptions =
        ref.read(adminRepositoryProvider)?.rooms() ?? Future.value(const []);
  }

  Future<List<Map<String, dynamic>>> _load() {
    final repo = ref.read(adminRepositoryProvider);
    if (repo == null) return Future.value(const []);
    return switch (widget.section) {
      AdminSection.hotels => repo.hotels(),
      AdminSection.rooms => repo.rooms(),
      AdminSection.availability => repo.availability(),
      AdminSection.bookings => repo.bookings(status: status),
      AdminSection.reviews => repo.reviews(),
      AdminSection.dashboard => repo.bookings(),
    };
  }

  void _refresh() => setState(() => future = _load());

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: _AdminSurface(
            child: _EmptyState(
              message:
                  'Could not load this section. Check access and try again.',
            ),
          ),
        );
      }
      final sourceRows = snapshot.data ?? const [];
      final rows = sourceRows.where(_matches).toList();
      final canCreate =
          widget.section == AdminSection.hotels ||
          widget.section == AdminSection.rooms ||
          widget.section == AdminSection.availability;
      final expanded =
          MediaQuery.sizeOf(context).width >= StayEasyBreakpoints.expandedStart;
      final title = _label(widget.section);
      final subtitle = switch (widget.section) {
        AdminSection.hotels => 'Manage property inventory and visibility.',
        AdminSection.rooms => 'Manage room types, rates and capacity.',
        AdminSection.availability => 'Control room inventory by date.',
        AdminSection.bookings => 'Review guest stays and booking details.',
        AdminSection.reviews => 'Review guest feedback and moderation status.',
        AdminSection.dashboard => '',
      };
      return ListView(
        padding: EdgeInsets.fromLTRB(
          expanded ? StayEasySpacing.space40 : StayEasySpacing.space24,
          StayEasySpacing.space32,
          expanded ? StayEasySpacing.space40 : StayEasySpacing.space24,
          StayEasySpacing.space40,
        ),
        children: [
          AdminPageHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 24),
          _toolbar(context, sourceRows, canCreate),
          const SizedBox(height: 16),
          if (widget.section == AdminSection.availability)
            _AvailabilityCalendar(rows: rows)
          else if (rows.isEmpty)
            _AdminSurface(
              child: _EmptyState(
                message: search.isNotEmpty
                    ? 'No results match your search and filters.'
                    : widget.section == AdminSection.bookings
                    ? 'No bookings found.'
                    : 'Nothing to show yet.',
              ),
            )
          else
            _resultsSurface(context, rows),
        ],
      );
    },
  );

  Widget _toolbar(
    BuildContext context,
    List<Map<String, dynamic>> sourceRows,
    bool canCreate,
  ) {
    if (widget.section == AdminSection.availability) {
      return _AvailabilityControls(
        rooms: roomOptions,
        selectedRoomId: roomFilter == 'all' ? null : roomFilter,
        onRoomChanged: (value) => setState(() => roomFilter = value ?? 'all'),
        onApply: _applyAvailability,
      );
    }
    final cities =
        sourceRows
            .map((row) => row['city'])
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final months =
        sourceRows
            .map((row) => '${row['check_in'] ?? ''}'.split('T').first)
            .where((value) => value.length >= 7)
            .map((value) => value.substring(0, 7))
            .toSet()
            .toList()
          ..sort();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          height: 44,
          child: TextField(
            onChanged: (value) =>
                setState(() => search = value.trim().toLowerCase()),
            style: StayEasyTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search ${_label(widget.section).toLowerCase()}…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: StayEasyColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: StayEasyRadii.rounded12,
                borderSide: const BorderSide(color: StayEasyColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: StayEasyRadii.rounded12,
                borderSide: const BorderSide(color: StayEasyColors.border),
              ),
            ),
          ),
        ),
        if (widget.section == AdminSection.hotels && cities.isNotEmpty)
          _FilterDropdown<String>(
            value: city,
            hint: 'All cities',
            items: ['all', ...cities],
            label: (value) => value == 'all' ? 'All cities' : value,
            onChanged: (value) => setState(() => city = value),
          ),
        if (widget.section == AdminSection.rooms)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: hotelOptions,
            builder: (context, snapshot) => _FilterDropdown<String>(
              value: hotelFilter ?? 'all',
              hint: 'All hotels',
              items: [
                'all',
                for (final hotel in snapshot.data ?? const [])
                  hotel['id'] as String,
              ],
              label: (value) => value == 'all'
                  ? 'All hotels'
                  : (snapshot.data ?? const []).firstWhere(
                          (hotel) => hotel['id'] == value,
                          orElse: () => {'name': 'Hotel'},
                        )['name']
                        as String,
              onChanged: (value) =>
                  setState(() => hotelFilter = value == 'all' ? null : value),
            ),
          ),
        if (widget.section == AdminSection.reviews)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: hotelOptions,
            builder: (context, snapshot) => _FilterDropdown<String>(
              value: hotelFilter ?? 'all',
              hint: 'All hotels',
              items: [
                'all',
                for (final hotel in snapshot.data ?? const [])
                  hotel['id'] as String,
              ],
              label: (value) => value == 'all'
                  ? 'All hotels'
                  : (snapshot.data ?? const []).firstWhere(
                          (hotel) => hotel['id'] == value,
                          orElse: () => {'name': 'Hotel'},
                        )['name']
                        as String,
              onChanged: (value) =>
                  setState(() => hotelFilter = value == 'all' ? null : value),
            ),
          ),
        if (widget.section == AdminSection.hotels ||
            widget.section == AdminSection.rooms)
          _FilterDropdown<String>(
            value: status,
            hint: 'All statuses',
            items: const ['all', 'active', 'inactive'],
            label: (value) => switch (value) {
              'all' => 'All statuses',
              'active' => 'Active',
              _ => 'Inactive',
            },
            onChanged: (value) => setState(() => status = value),
          ),
        if (widget.section == AdminSection.bookings)
          _FilterDropdown<String>(
            value: status,
            hint: 'All statuses',
            items: const ['all', 'confirmed', 'cancelled'],
            label: (value) =>
                value == 'all' ? 'All statuses' : _titleCase(value),
            onChanged: (value) => setState(() {
              status = value;
              future = _load();
            }),
          ),
        if (widget.section == AdminSection.bookings && months.isNotEmpty)
          _FilterDropdown<String>(
            value: month,
            hint: 'Any date',
            items: ['all', ...months],
            label: (value) => value == 'all' ? 'Any date' : _monthLabel(value),
            onChanged: (value) => setState(() => month = value),
          ),
        if (widget.section == AdminSection.reviews)
          _FilterDropdown<String>(
            value: status,
            hint: 'All reviews',
            items: const ['all', 'unverified', 'verified'],
            label: (value) =>
                value == 'all' ? 'All reviews' : _titleCase(value),
            onChanged: (value) => setState(() => status = value),
          ),
        if (canCreate)
          FilledButton.icon(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              widget.section == AdminSection.availability
                  ? 'Set availability'
                  : 'Add ${widget.section == AdminSection.hotels ? 'hotel' : 'room'}',
            ),
          ),
      ],
    );
  }

  Future<void> _applyAvailability(
    String roomId,
    DateTime from,
    DateTime to,
    int count,
    double? price,
  ) async {
    try {
      await ref
          .read(adminRepositoryProvider)!
          .upsertAvailability(roomId, from, to, count, price);
      _refresh();
      _message('Availability updated.');
    } catch (_) {
      _message(
        'Could not update availability. Check admin access and try again.',
      );
    }
  }

  bool _matches(Map<String, dynamic> row) {
    if (widget.section == AdminSection.availability &&
        roomFilter != 'all' &&
        row['room_id'] != roomFilter) {
      return false;
    }
    if (widget.section == AdminSection.reviews &&
        hotelFilter != null &&
        row['hotel_id'] != hotelFilter) {
      return false;
    }
    if (widget.section == AdminSection.rooms &&
        hotelFilter != null &&
        row['hotel_id'] != hotelFilter) {
      return false;
    }
    if (widget.section == AdminSection.hotels &&
        city != 'all' &&
        row['city'] != city) {
      return false;
    }
    if ((widget.section == AdminSection.hotels ||
            widget.section == AdminSection.rooms) &&
        status != 'all' &&
        row['is_active'] != (status == 'active')) {
      return false;
    }
    if (widget.section == AdminSection.reviews &&
        status != 'all' &&
        row['is_verified'] != (status == 'verified')) {
      return false;
    }
    if (widget.section == AdminSection.bookings &&
        month != 'all' &&
        !'${row['check_in']}'.startsWith(month)) {
      return false;
    }
    if (search.isEmpty) return true;
    final values = [
      row['name'],
      row['slug'],
      row['city'],
      row['address'],
      row['booking_code'],
      row['guest_name'],
      row['guest_email'],
      row['check_in'],
      row['check_out'],
      row['title'],
      row['body'],
      row['rating'],
      row['price_per_night'],
      (row['hotels'] as Map?)?['name'],
      (row['rooms'] as Map?)?['name'],
    ];
    return values.whereType<Object>().any(
      (value) => '$value'.toLowerCase().contains(search),
    );
  }

  Widget _resultsSurface(
    BuildContext context,
    List<Map<String, dynamic>> rows,
  ) {
    if (widget.section == AdminSection.rooms) {
      final width = MediaQuery.sizeOf(context).width;
      final columns = width >= 1280
          ? 3
          : width >= 900
          ? 2
          : 1;
      return _AdminSurface(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 3
              ? 1.05
              : columns == 2
              ? 0.95
              : 0.88,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final row in rows) _roomCard(context, row)],
        ),
      );
    }
    return _AdminSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _rowCard(context, rows[index]),
            if (index + 1 < rows.length) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _rowCard(BuildContext context, Map<String, dynamic> row) {
    switch (widget.section) {
      case AdminSection.hotels:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: StayEasyRadii.rounded12,
                child: Image.asset(
                  _hotelFallback('${row['city'] ?? ''}'),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const _LeadingIcon(icon: Icons.hotel_outlined),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['name']}',
                      style: StayEasyTypography.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row['city']} · ${row['address'] ?? 'Address not set'} · ★ ${row['rating'] ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StayEasyTypography.bodySmall.copyWith(
                        color: StayEasyColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${((row['rooms'] as List?) ?? const []).length} room types',
                      style: StayEasyTypography.bodySmall.copyWith(
                        color: StayEasyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(
                status: row['is_active'] == true ? 'Active' : 'Inactive',
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Edit hotel',
                onPressed: () => _editHotel(context, row),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: row['is_active'] == true
                    ? 'Deactivate hotel'
                    : 'Activate hotel',
                onPressed: () => _toggleHotel(row),
                icon: Icon(
                  row['is_active'] == true
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
              ),
            ],
          ),
        );
      case AdminSection.rooms:
        return _roomCard(context, row);
      case AdminSection.availability:
        return const SizedBox.shrink();
      case AdminSection.bookings:
        final hotel = row['hotels'] as Map?;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;
              final details = [
                _LedgerField(
                  label: 'GUEST',
                  value: '${row['guest_name']}',
                  flex: 2,
                ),
                _LedgerField(
                  label: 'PROPERTY',
                  value:
                      '${hotel?['name'] ?? 'Hotel'}${hotel?['city'] == null ? '' : ', ${hotel?['city']}'}',
                  flex: 2,
                ),
                _LedgerField(
                  label: 'ROOM',
                  value: '${(row['rooms'] as Map?)?['name'] ?? 'Room'}',
                  flex: 2,
                ),
                _LedgerField(
                  label: 'STAY',
                  value: '${row['check_in']} — ${row['check_out']}',
                  flex: 2,
                ),
                _LedgerField(
                  label: 'TOTAL',
                  value: '₹${row['total_price']}',
                  flex: 1,
                ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _LeadingIcon(
                        icon: Icons.confirmation_number_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${row['booking_code']}',
                          style: StayEasyTypography.labelLarge,
                        ),
                      ),
                      _StatusChip(status: _titleCase('${row['status']}')),
                    ],
                  ),
                  if (compact) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: details
                          .map((field) => SizedBox(width: 210, child: field))
                          .toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        for (final field in details)
                          Expanded(flex: field.flex, child: field),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        );
      case AdminSection.reviews:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: StayEasyColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${row['rating']} / 5',
                      style: StayEasyTypography.labelLarge,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${(row['hotels'] as Map?)?['name'] ?? 'Hotel review'} · ${(row['rooms'] as Map?)?['name'] ?? 'Hotel-level review'}',
                        style: StayEasyTypography.bodySmall.copyWith(
                          color: StayEasyColors.textSecondary,
                        ),
                      ),
                    ),
                    _StatusChip(
                      status: row['is_verified'] == true
                          ? 'Verified'
                          : 'Unverified',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if ('${row['title'] ?? ''}'.isNotEmpty)
                  Text('${row['title']}', style: StayEasyTypography.labelLarge),
                const SizedBox(height: 4),
                Text(
                  '${row['body'] ?? ''}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: StayEasyTypography.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Helpful ${row['helpful_count'] ?? 0}',
                      style: StayEasyTypography.bodySmall.copyWith(
                        color: StayEasyColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (constraints.maxWidth >= 500)
                      TextButton.icon(
                        onPressed: () => _moderate(row),
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: Text(
                          row['is_verified'] == true
                              ? 'Mark unverified'
                              : 'Verify review',
                        ),
                      )
                    else
                      IconButton(
                        tooltip: row['is_verified'] == true
                            ? 'Mark unverified'
                            : 'Verify review',
                        onPressed: () => _moderate(row),
                        icon: const Icon(Icons.fact_check_outlined),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      case AdminSection.dashboard:
        return const SizedBox.shrink();
    }
  }

  Widget _roomCard(BuildContext context, Map<String, dynamic> row) => Container(
    decoration: BoxDecoration(
      color: StayEasyColors.surface,
      border: Border.all(color: StayEasyColors.border),
      borderRadius: StayEasyRadii.rounded16,
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/room-detail.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: StayEasyColors.surfaceVariant,
                  child: Icon(
                    Icons.bed_outlined,
                    size: 36,
                    color: StayEasyColors.primary,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: _StatusChip(
                  status: row['is_active'] == true ? 'Active' : 'Inactive',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StayEasyTypography.titleMedium,
                ),
                Text(
                  '${(row['hotels'] as Map?)?['name'] ?? 'Hotel'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StayEasyTypography.bodySmall.copyWith(
                    color: StayEasyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    Chip(label: Text('₹${row['price_per_night']} / night')),
                    Chip(label: Text('${row['capacity']} guests')),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _editRoom(context, row),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          _editAvailability(context, row['id'] as String),
                      child: const Text('Availability'),
                    ),
                    IconButton(
                      tooltip: row['is_active'] == true
                          ? 'Deactivate room'
                          : 'Activate room',
                      onPressed: () => _toggleRoom(row),
                      icon: Icon(
                        row['is_active'] == true
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _create(BuildContext context) async {
    if (widget.section == AdminSection.availability) {
      await _editAvailability(context);
      return;
    }
    final isHotel = widget.section == AdminSection.hotels;
    final hotels = !isHotel
        ? await ref.read(adminRepositoryProvider)!.hotels()
        : null;
    if (!context.mounted) return;
    final values = await _editFields(
      context,
      isHotel ? 'New hotel' : 'New room',
      isHotel
          ? [
              'name',
              'slug',
              'city',
              'address',
              'description',
              'amenities',
              'image_urls',
            ]
          : [
              'hotel_id',
              'name',
              'description',
              'price_per_night',
              'capacity',
              'bed_type',
              'room_size',
              'total_inventory',
              'amenities',
            ],
      hotels: hotels,
    );
    if (values == null) return;
    try {
      if (isHotel) {
        await ref.read(adminRepositoryProvider)!.saveHotel({
          ...values,
          'amenities': _array(values.remove('amenities')),
          'image_urls': _array(values.remove('image_urls')),
          'is_active': true,
        });
      } else {
        await ref.read(adminRepositoryProvider)!.saveRoom({
          ...values,
          'price_per_night': double.parse(values.remove('price_per_night')!),
          'capacity': int.parse(values.remove('capacity')!),
          'room_size': double.tryParse(values.remove('room_size')!),
          'total_inventory': int.parse(values.remove('total_inventory')!),
          'amenities': _array(values.remove('amenities')),
          'is_active': true,
        });
      }
      _refresh();
    } catch (_) {
      _message('Could not save. Check the form fields and try again.');
    }
  }

  Future<void> _editHotel(
    BuildContext context,
    Map<String, dynamic> row,
  ) async {
    final values = await _editFields(context, 'Edit hotel', [
      'name',
      'slug',
      'city',
      'address',
      'description',
      'amenities',
      'image_urls',
    ], initial: row);
    if (values == null) {
      return;
    }
    try {
      await ref.read(adminRepositoryProvider)!.saveHotel({
        ...values,
        'amenities': _array(values.remove('amenities')),
        'image_urls': _array(values.remove('image_urls')),
      }, id: row['id'] as String);
      _refresh();
    } catch (_) {
      _message('Could not save hotel.');
    }
  }

  Future<void> _editRoom(BuildContext context, Map<String, dynamic> row) async {
    final hotels = await ref.read(adminRepositoryProvider)!.hotels();
    if (!context.mounted) return;
    final values = await _editFields(
      context,
      'Edit room',
      [
        'hotel_id',
        'name',
        'description',
        'price_per_night',
        'capacity',
        'bed_type',
        'room_size',
        'total_inventory',
        'amenities',
      ],
      initial: row,
      hotels: hotels,
    );
    if (values == null) {
      return;
    }
    try {
      await ref.read(adminRepositoryProvider)!.saveRoom({
        ...values,
        'price_per_night': double.parse(values.remove('price_per_night')!),
        'capacity': int.parse(values.remove('capacity')!),
        'room_size': double.tryParse(values.remove('room_size')!),
        'total_inventory': int.parse(values.remove('total_inventory')!),
        'amenities': _array(values.remove('amenities')),
      }, id: row['id'] as String);
      _refresh();
    } catch (_) {
      _message('Could not save room.');
    }
  }

  Future<void> _toggleHotel(Map<String, dynamic> row) async {
    await ref.read(adminRepositoryProvider)!.saveHotel({
      'is_active': row['is_active'] != true,
    }, id: row['id'] as String);
    _refresh();
  }

  Future<void> _toggleRoom(Map<String, dynamic> row) async {
    await ref.read(adminRepositoryProvider)!.saveRoom({
      'is_active': row['is_active'] != true,
    }, id: row['id'] as String);
    _refresh();
  }

  Future<void> _moderate(Map<String, dynamic> row) async {
    final verified = row['is_verified'] != true;
    try {
      await ref
          .read(adminRepositoryProvider)!
          .moderateReview(
            row['id'] as String,
            verified: verified,
            helpfulCount: row['helpful_count'] as int? ?? 0,
          );
      _refresh();
    } catch (_) {
      _message('Review moderation is unavailable.');
    }
  }

  Future<void> _editAvailability(
    BuildContext context, [
    String? selectedRoomId,
  ]) async {
    final rooms = await ref.read(adminRepositoryProvider)!.rooms();
    if (!context.mounted) {
      return;
    }
    final room = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _AvailabilityDialog(rooms: rooms, initialRoomId: selectedRoomId),
    );
    if (room == null) return;
    try {
      await ref
          .read(adminRepositoryProvider)!
          .upsertAvailability(
            room['room_id'] as String,
            room['from'] as DateTime,
            room['to'] as DateTime,
            room['count'] as int,
            room['price'] as double?,
          );
      _refresh();
    } catch (_) {
      _message('Could not update availability.');
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }
}

class _AvailabilityDialog extends StatefulWidget {
  const _AvailabilityDialog({required this.rooms, this.initialRoomId});
  final List<Map<String, dynamic>> rooms;
  final String? initialRoomId;
  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  final formKey = GlobalKey<FormState>();
  String? roomId;
  DateTime from = DateTime(2026, 10, 1), to = DateTime(2026, 10, 2);
  final count = TextEditingController(text: '2');
  final price = TextEditingController();
  @override
  void initState() {
    super.initState();
    roomId = widget.initialRoomId;
  }

  @override
  void dispose() {
    count.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: StayEasyRadii.rounded20),
    title: const Text('Set availability', style: StayEasyTypography.titleLarge),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 440,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: roomId,
                decoration: const InputDecoration(labelText: 'Room'),
                items: [
                  for (final r in widget.rooms)
                    DropdownMenuItem(
                      value: r['id'] as String,
                      child: Text(
                        '${r['name']} · ${(r['hotels'] as Map?)?['name'] ?? ''}',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => roomId = v),
              ),
              TextFormField(
                controller: count,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Available rooms (0 for unavailable)',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  return parsed == null || parsed < 0
                      ? 'Enter zero or a positive whole number'
                      : null;
                },
              ),
              TextFormField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price override (optional)',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = double.tryParse(text);
                  return parsed == null || parsed <= 0
                      ? 'Enter a positive INR price'
                      : null;
                },
              ),
              ListTile(
                title: Text('From ${from.toIso8601String().substring(0, 10)}'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: from,
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2035),
                  );
                  if (d != null) setState(() => from = d);
                },
              ),
              ListTile(
                title: Text(
                  'Checkout ${to.toIso8601String().substring(0, 10)}',
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: to,
                    firstDate: from.add(const Duration(days: 1)),
                    lastDate: DateTime(2035),
                  );
                  if (d != null) setState(() => to = d);
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (roomId == null || !formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'room_id': roomId,
            'from': from,
            'to': to,
            'count': int.parse(count.text),
            'price': double.tryParse(price.text),
          });
        },
        child: const Text('Save'),
      ),
    ],
  );
}

Future<Map<String, String>?> _editFields(
  BuildContext context,
  String title,
  List<String> fields, {
  Map<String, dynamic>? initial,
  List<Map<String, dynamic>>? hotels,
}) async {
  final formKey = GlobalKey<FormState>();
  final controllers = {
    for (final field in fields)
      field: TextEditingController(
        text:
            (initial?[field] is List
                ? (initial![field] as List).join(', ')
                : initial?[field]?.toString()) ??
            '',
      ),
  };
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields)
                  if (field == 'hotel_id' && hotels != null)
                    DropdownButtonFormField<String>(
                      initialValue: controllers[field]!.text.isEmpty
                          ? null
                          : controllers[field]!.text,
                      decoration: const InputDecoration(labelText: 'Hotel'),
                      items: [
                        for (final hotel in hotels)
                          DropdownMenuItem(
                            value: hotel['id'] as String,
                            child: Text('${hotel['name']} · ${hotel['city']}'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) controllers[field]!.text = value;
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    )
                  else
                    TextFormField(
                      controller: controllers[field],
                      decoration: InputDecoration(
                        labelText: field.replaceAll('_', ' '),
                      ),
                      maxLines: field == 'description' ? 3 : 1,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (const {
                              'name',
                              'slug',
                              'city',
                              'hotel_id',
                              'price_per_night',
                              'capacity',
                              'bed_type',
                              'total_inventory',
                            }.contains(field) &&
                            text.isEmpty) {
                          return 'Required';
                        }
                        if (field == 'price_per_night' &&
                            (double.tryParse(text) == null ||
                                double.parse(text) < 0)) {
                          return 'Enter a valid INR price';
                        }
                        if (const {
                              'capacity',
                              'total_inventory',
                            }.contains(field) &&
                            (int.tryParse(text) == null ||
                                int.parse(text) <= 0)) {
                          return 'Enter a positive whole number';
                        }
                        if (field == 'room_size' &&
                            text.isNotEmpty &&
                            (double.tryParse(text) == null ||
                                double.parse(text) <= 0)) {
                          return 'Enter a positive room size';
                        }
                        return null;
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, {
                for (final e in controllers.entries) e.key: e.value.text.trim(),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  for (final c in controllers.values) {
    c.dispose();
  }
  return result;
}

List<String> _array(String? value) => value == null || value.trim().isEmpty
    ? const []
    : value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

class _FilterDropdown<T extends Object> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.label,
    required this.onChanged,
  });
  final T value;
  final String hint;
  final List<T> items;
  final String Function(T value) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: StayEasyColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: StayEasyRadii.rounded12,
          borderSide: const BorderSide(color: StayEasyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: StayEasyRadii.rounded12,
          borderSide: const BorderSide(color: StayEasyColors.border),
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(label(item))),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color =
        normalized == 'active' ||
            normalized == 'confirmed' ||
            normalized == 'verified'
        ? StayEasyColors.success
        : normalized == 'inactive' || normalized == 'cancelled'
        ? StayEasyColors.textSecondary
        : StayEasyColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: StayEasyRadii.rounded8,
      ),
      child: Text(
        status,
        style: StayEasyTypography.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _LedgerField extends StatelessWidget {
  const _LedgerField({required this.label, required this.value, this.flex = 1});
  final String label, value;
  final int flex;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: StayEasyTypography.caption.copyWith(
          color: StayEasyColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: StayEasyTypography.bodySmall,
      ),
    ],
  );
}

class _AvailabilityControls extends StatefulWidget {
  const _AvailabilityControls({
    required this.rooms,
    required this.selectedRoomId,
    required this.onRoomChanged,
    required this.onApply,
  });
  final Future<List<Map<String, dynamic>>> rooms;
  final String? selectedRoomId;
  final ValueChanged<String?> onRoomChanged;
  final Future<void> Function(
    String roomId,
    DateTime from,
    DateTime to,
    int count,
    double? price,
  )
  onApply;

  @override
  State<_AvailabilityControls> createState() => _AvailabilityControlsState();
}

class _AvailabilityControlsState extends State<_AvailabilityControls> {
  final _form = GlobalKey<FormState>();
  final _count = TextEditingController(text: '2');
  final _price = TextEditingController();
  late DateTime _from = DateTime(2026, 10, 1);
  late DateTime _to = DateTime(2026, 10, 2);
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _roomId = widget.selectedRoomId;
  }

  @override
  void didUpdateWidget(covariant _AvailabilityControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoomId != widget.selectedRoomId) {
      _roomId = widget.selectedRoomId;
    }
  }

  @override
  void dispose() {
    _count.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AdminSurface(
    padding: const EdgeInsets.all(20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth < 500
            ? constraints.maxWidth
            : null;
        return Form(
          key: _form,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: fieldWidth ?? 280,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: widget.rooms,
                  builder: (context, snapshot) => DropdownButtonFormField<String>(
                    initialValue: _roomId,
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      prefixIcon: Icon(Icons.bed_outlined),
                    ),
                    items: [
                      for (final room in snapshot.data ?? const [])
                        DropdownMenuItem(
                          value: room['id'] as String,
                          child: Text(
                            '${room['name']} · ${(room['hotels'] as Map?)?['name'] ?? ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? 'Select a room' : null,
                    onChanged: (value) {
                      setState(() => _roomId = value);
                      widget.onRoomChanged(value);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth ?? 150,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _from,
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2035),
                    );
                    if (date != null) {
                      setState(() {
                        _from = date;
                        if (!_to.isAfter(date)) {
                          _to = date.add(const Duration(days: 1));
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('From ${_shortDate(_from)}'),
                ),
              ),
              SizedBox(
                width: fieldWidth ?? 150,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _to,
                      firstDate: _from.add(const Duration(days: 1)),
                      lastDate: DateTime(2035),
                    );
                    if (date != null) setState(() => _to = date);
                  },
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text('To ${_shortDate(_to)}'),
                ),
              ),
              SizedBox(
                width: fieldWidth ?? 135,
                child: TextFormField(
                  controller: _count,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Available rooms',
                    isDense: true,
                  ),
                  validator: (value) {
                    final count = int.tryParse(value ?? '');
                    return count == null || count < 0
                        ? 'Enter 0 or more'
                        : null;
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth ?? 180,
                child: TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price override (optional)',
                    prefixText: '₹ ',
                    isDense: true,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final amount = double.tryParse(text);
                    return amount == null || amount <= 0
                        ? 'Enter a positive INR price'
                        : null;
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (_roomId == null || !_form.currentState!.validate()) {
                    return;
                  }
                  if (!_to.isAfter(_from)) {
                    return;
                  }
                  await widget.onApply(
                    _roomId!,
                    _from,
                    _to,
                    int.parse(_count.text),
                    _price.text.trim().isEmpty
                        ? null
                        : double.parse(_price.text),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _AvailabilityCalendar extends StatelessWidget {
  const _AvailabilityCalendar({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final inventory = <int, int>{};
    for (final row in rows) {
      final day = DateTime.tryParse('${row['date']}');
      if (day != null && day.year == 2026 && day.month == 10) {
        inventory.update(
          day.day,
          (current) => current + (row['available_rooms'] as int? ?? 0),
          ifAbsent: () => row['available_rooms'] as int? ?? 0,
        );
      }
    }
    return _AdminSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'October 2026',
                  style: StayEasyTypography.titleLarge,
                ),
              ),
              const _StatusChip(status: 'Availability'),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final minWidth = constraints.maxWidth < 640
                  ? 640.0
                  : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final day in [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ])
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    day,
                                    style: StayEasyTypography.labelMedium
                                        .copyWith(
                                          color: StayEasyColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 35,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: ((minWidth - 48) / 7) / 72,
                        ),
                        itemBuilder: (context, index) {
                          final day =
                              index - 3 + 1; // October 1, 2026 is Thursday.
                          if (day < 1 || day > 31) {
                            return const SizedBox.shrink();
                          }
                          final count = inventory[day];
                          final color = count == null
                              ? StayEasyColors.textSecondary
                              : count == 0
                              ? StayEasyColors.error
                              : count <= 2
                              ? StayEasyColors.warning
                              : StayEasyColors.success;
                          final background = count == null
                              ? StayEasyColors.background
                              : color.withValues(alpha: 0.08);
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: background,
                              border: Border.all(color: StayEasyColors.border),
                              borderRadius: StayEasyRadii.rounded12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$day',
                                  style: StayEasyTypography.labelLarge,
                                ),
                                Text(
                                  count == null
                                      ? 'Not set'
                                      : count == 0
                                      ? 'Unavailable'
                                      : count <= 2
                                      ? '$count left'
                                      : '$count rooms',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: StayEasyTypography.caption.copyWith(
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _LegendDot(color: StayEasyColors.success, label: 'Available'),
              _LegendDot(color: StayEasyColors.warning, label: 'Limited'),
              _LegendDot(color: StayEasyColors.error, label: 'Unavailable'),
              _LegendDot(
                color: StayEasyColors.textSecondary,
                label: 'Not configured',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: StayEasyTypography.bodySmall.copyWith(
          color: StayEasyColors.textSecondary,
        ),
      ),
    ],
  );
}

String _titleCase(String text) => text.isEmpty
    ? text
    : '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';

String _monthLabel(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return value;
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final monthIndex = int.tryParse(parts[1]);
  return monthIndex != null && monthIndex >= 1 && monthIndex <= 12
      ? '${names[monthIndex - 1]} ${parts[0]}'
      : value;
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} ${_monthLabel('${value.year}-${value.month.toString().padLeft(2, '0')}')}';

String _hotelFallback(String city) => switch (city.toLowerCase()) {
  'mumbai' => 'assets/images/mercer.png',
  'goa' => 'assets/images/cala-house.png',
  'udaipur' => 'assets/images/atelier.png',
  'manali' => 'assets/images/dune-pine.png',
  _ => 'assets/images/hotel-detail.png',
};
