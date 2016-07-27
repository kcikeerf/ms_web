'use strict';

/**
 * Config for the router
 */
angular.module('app')
  .run(
    [          '$rootScope', '$state', '$stateParams',
      function ($rootScope,   $state,   $stateParams) {
          $rootScope.$state = $state;
          $rootScope.$stateParams = $stateParams;        
      }
    ]
  )
  .config(
    [          '$stateProvider', '$urlRouterProvider',
      function ($stateProvider,   $urlRouterProvider) {
          
          $urlRouterProvider
              .otherwise('/app/chart/diagnosis');
          $stateProvider
              .state('app', {
                  abstract: true,
                  url: '/app',
                  templateUrl: '/classreport/tpl/app.html'
              })
              .state('app.chart', {
                  url: '/chart',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.chart.diagnosis', {
                  url: '/diagnosis',
                  templateUrl: '/classreport/tpl/ui_chart_diagnosis.html'
              })
              .state('app.chart.scale', {
                  url: '/scale',
                  templateUrl: '/classreport/tpl/ui_chart_scale.html'
              })
              // table
              .state('app.table', {
                  url: '/table',
                  template: '<div ui-view class="fade-in-up"></div>'
              })
              .state('app.table.KnowledgeDatatable', {
                  url: '/KnowledgeDatatable',
                  templateUrl: '/classreport/tpl/table_datatable1.html'
              })
              .state('app.table.SkillDatatable', {
                  url: '/SkillDatatable',
                  templateUrl: '/classreport/tpl/table_datatable2.html'
              })
              .state('app.table.CapacityDatatable', {
                  url: '/CapacityDatatable',
                  templateUrl: '/classreport/tpl/table_datatable3.html'
              })
              .state('app.table.static', {
                  url: '/static',
                  templateUrl: '/classreport/tpl/table_static.html',
                  resolve: {
                      deps: ['$ocLazyLoad',
                        function( $ocLazyLoad ){
                          return $ocLazyLoad.load('ngGrid').then(
                              function(){
                                  return $ocLazyLoad.load('/classreport/js/controllers/grid.js');
                              }
                          );
                      }]
                  }
              })
              // pages
              .state('app.page', {
                  url: '/page',
                  template: '<div ui-view class="fade-in-down"></div>'
              })
              .state('app.docs1', {
                  url: '/unscramble1',
                  templateUrl: '/classreport/tpl/unscramble1.html'
              })
              .state('app.docs2', {
                  url: '/unscramble2',
                  templateUrl: '/classreport/tpl/unscramble2.html'
              })
              .state('app.docs3', {
                  url: '/unscramble3',
                  templateUrl: '/classreport/tpl/unscramble3.html'
              })
              .state('app.docs4', {
                  url: '/evaluate1',
                  templateUrl: '/classreport/tpl/evaluate1.html'
              })
              .state('app.docs5', {
                  url: '/evaluate2',
                  templateUrl: '/classreport/tpl/evaluate2.html'
              })
              .state('app.docs6', {
                  url: '/evaluate3',
                  templateUrl: '/classreport/tpl/evaluate3.html'
              })
              .state('app.docs7', {
                  url: '/evaluate4',
                  templateUrl: '/classreport/tpl/evaluate4.html'
              })
      }
    ]
  );